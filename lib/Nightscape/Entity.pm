use v6;
use Nightscape::Entity::COA;
use Nightscape::Entity::Holding;
use Nightscape::Entity::TXN;
use Nightscape::Entity::Wallet;
use Nightscape::Entry;
use Nightscape::Types;
unit class Nightscape::Entity;

# entity name
has VarName $.entity-name is required;

# entity base currency
has AssetCode $.entity-base-currency =
    $GLOBAL::CONF ?? $GLOBAL::CONF.resolve-base-currency($!entity-name)
                  !! "USD";

# chart of accounts
has Nightscape::Entity::COA $.coa;

# entries by this entity
has Nightscape::Entry @.entries;

# holdings with cost basis, indexed by asset code
has Nightscape::Entity::Holding %.holdings{AssetCode};

# transactions queue
has Nightscape::Entity::TXN @.transactions;

# wallets indexed by silo
has Nightscape::Entity::Wallet %.wallet{Silo} =
    ::(ASSETS) => Nightscape::Entity::Wallet.new,
    ::(EXPENSES) => Nightscape::Entity::Wallet.new,
    ::(INCOME) => Nightscape::Entity::Wallet.new,
    ::(LIABILITIES) => Nightscape::Entity::Wallet.new,
    ::(EQUITY) => Nightscape::Entity::Wallet.new;

# given holdings + wallet, return wllt including capital gains / losses
method acct2wllt(
    Nightscape::Entity::COA::Acct:D :%acct! is readonly,
    Nightscape::Entity::Holding:D :%holdings is readonly = %.holdings,
    Nightscape::Entity::Wallet:D :%wallet is readonly = %.wallet
) returns Hash[Nightscape::Entity::Wallet:D,Silo:D]
{
    # make copy of %wallet for incising realized capital gains / losses
    my Nightscape::Entity::Wallet:D %wllt{Silo:D} = clone-wallet(:%wallet);
    self!incise-capital-gains-and-losses(:%acct, :%holdings, :%wallet, :%wllt);
    %wllt;
}

sub clone-wallet(
    Nightscape::Entity::Wallet:D :%wallet! is readonly
) returns Hash[Nightscape::Entity::Wallet:D,Silo:D]
{
    my Nightscape::Entity::Wallet:D %wllt{Silo:D};
    for %wallet.kv -> $silo, $wallet
    {
        %wllt{::($silo)} = $wallet.clone;
    }
    %wllt;
}

sub contains-capital-gains-losses(
    Nightscape::Entity::Holding::Taxes:D @taxes
) returns Bool:D
{
    my FatRat $capital-gains = [+] @taxes».capital-gains;
    my FatRat $capital-losses = [+] @taxes».capital-losses;
    $capital-gains || $capital-losses ?? True !! False;
}

# modify %wllt on a per $tax-id basis using %instructions
method !incise-capital-gains-and-losses(
    Nightscape::Entity::COA::Acct:D :%acct! is readonly,
    Nightscape::Entity::Holding:D :%holdings! is readonly,
    Nightscape::Entity::Wallet:D :%wallet! is readonly,
    Nightscape::Entity::Wallet:D :%wllt!
)
{
    # for each asset code in holdings
    for %holdings.kv -> $asset-code, $holdings
    {
        # fetch costing method for asset code
        my Costing $costing = $GLOBAL::CONF.resolve-costing(
            :$asset-code,
            :$.entity-name
        );

        # for each EntryID resulting in realized capital gains / losses for
        # this asset code
        for $holdings.taxes.kv -> $tax-id, @taxes
        {
            unless contains-capital-gains-losses(@taxes)
            {
                next;
            }

            # ensure all original quantities expended are quoted in the
            # asset code $asset-code, and that acquisition price is
            # quoted in entity's base currency
            self.perform-sanity-check(:$asset-code, :@taxes);

            # fetch all accts containing this asset code with changesets created
            # from EntryID $tax-id
            # - associated realized capital gains / losses must have resulted
            #   from the assorted changesets in these wallets
            my Nightscape::Entity::COA::Acct:D %acct-targets{AcctName:D} =
                resolve-acct-targets(:%acct, :$asset-code, :$tax-id);

            # total quantity debited in targets, separately and in total
            #
            #     TotalQuantityDebited => %(
            #         TargetAcctName => %(
            #             TargetAcctBalanceDelta => %(
            #                 PostingID => PostingIDBalanceDelta,
            #                 PostingID => PostingIDBalanceDelta,
            #                 PostingID => PostingIDBalanceDelta
            #             )
            #         ),
            #         TargetAcctName => %(
            #             TargetAcctBalanceDelta => %(
            #                 PostingID => PostingIDBalanceDelta,
            #                 PostingID => PostingIDBalanceDelta,
            #                 PostingID => PostingIDBalanceDelta
            #             )
            #         )
            #     )
            #
            # where:
            #
            # - TotalQuantityDebited is sum of all TargetAcctBalanceDelta
            # - TargetAcctName is COA::Acct.name ("ASSETS:Personal:Bankwest")
            # - TargetAcctBalanceDelta is sum of all PostingIDBalanceDelta
            # - PostingID is ID of posting in EntryID causing
            #   this round of realized capital gains / losses, wrt asset
            #   code $asset-code
            #   - get-total-quantity-debited calls
            #         Wallet.ls-changesets(
            #             asset-code => $asset-code,
            #             entry-id => $tax-id
            #         );
            # - PostingIDBalanceDelta is Changeset.balance-delta
            my Hash[Hash[Hash[FatRat:D,PostingID:D],FatRat:D],AcctName:D]
                %total-quantity-debited{Quantity:D} =
                    self!get-total-quantity-debited(
                        :%acct-targets,
                        :$asset-code,
                        :entry-id($tax-id),
                        :%wallet
                    );

            # total quantity expended, separately and in total
            my Hash[Quantity:D,Quantity:D]
                %total-quantity-expended{Quantity:D} =
                    get-total-quantity-expended(:$costing, :@taxes);

            self.perform-sanity-check(
                :%total-quantity-debited,
                :%total-quantity-expended
            );

            # fetch instructions for incising realized capital gains / losses
            # NEW/MOD | AcctName | QuantityToDebit | XE
            my Array[Instruction:D] %instructions{PostingID:D} =
                gen-instructions(
                    :%total-quantity-debited,
                    :%total-quantity-expended
                );

            self!mkincision(
                :$asset-code,
                :%instructions,
                :$tax-id,
                :@taxes,
                :%wllt
            );
        }
    }
}

method !mkincision(
    AssetCode:D :$asset-code!,
    Array[Instruction:D] :%instructions!,
    EntryID:D :$tax-id!,
    Nightscape::Entity::Holding::Taxes:D :@taxes! is readonly,
    Nightscape::Entity::Wallet:D :%wllt!
)
{
    # run another check to make sure, after instructions are
    # applied, the difference in total quantity debited in entity
    # base currency is balanced by the change to NSAutoCapitalGains
    self.perform-sanity-check(:%instructions, :$tax-id, :@taxes);

    # apply instructions to balance out NSAutoCapitalGains later
    for %instructions.kv -> $posting-id, @instructions
    {
        for @instructions -> $instruction
        {
            # get wallet path by splitting AcctName on ':'
            my VarName @path = $instruction<acct-name>.split(':');

            # make new changeset or modify existing, by instruction
            in-wallet(%wllt{::(@path[0])}, @path[1..*]).mkchangeset(
                :$asset-code,
                :xe-asset-code($.entity-base-currency),
                :entry-id($tax-id),
                :$posting-id,
                :$instruction
            );
        }
    }

    # incise silo INCOME with realized capital gains / losses
    for @taxes -> $tax-event
    {
        # store realized capital gains, realized capital losses
        #
        # use of Quantity subset type on Taxes.capital-gains
        # and Taxes.capital-losses proves neither capital gains
        # nor capital losses can be less than zero
        my Quantity $capital-gains = $tax-event.capital-gains;
        my Quantity $capital-losses = $tax-event.capital-losses;

        # get holding period and convert to wallet name
        my HoldingPeriod $holding-period = $tax-event.holding-period;
        my VarName $holding-period-name =
            $holding-period ~~ LONG-TERM ?? "LongTerm" !! "ShortTerm";

        # check that, if capital gains exist, capital losses
        # don't exist, and vice versa
        self.perform-sanity-check(:$capital-gains, :$capital-losses);

        # take difference of realized capital gains and losses
        my FatRat $gains-less-losses = $capital-gains - $capital-losses;

        # determine whether gain (INC) or loss (DEC)
        my DecInc $decinc;
        if $gains-less-losses > 0
        {
            $decinc = INC;
        }
        elsif $gains-less-losses < 0
        {
            $decinc = DEC;
        }

        # purposefully empty vars, not needed for NSAutoCapitalGains
        my PostingID $posting-id;
        my AssetCode $xeac;
        my Quantity $xeaq;

        # enter realized capital gains / losses in Silo INCOME
        in-wallet(
            %wllt{INCOME},
            "NSAutoCapitalGains",
            $holding-period-name
        ).mkchangeset(
            :entry-id($tax-id),
            :$posting-id,
            :asset-code($.entity-base-currency),
            :$decinc,
            :quantity($gains-less-losses.abs),
            :xe-asset-code($xeac),
            :xe-asset-quantity($xeaq)
        );
    }
}

multi method perform-sanity-check(
    AssetCode:D :$asset-code!,
    Nightscape::Entity::Holding::Taxes:D :@taxes! is readonly
)
{
    for @taxes
    {
        # was incorrect asset code expended?
        unless $_.quantity-expended-asset-code ~~ $asset-code
        {
            # error: improper asset code expended
            die "Sorry, improper asset code expended in tax event";
        }

        # did asset code used for acquisition price differ from
        # entity's base currency?
        unless $_.acquisition-price-asset-code ~~ $.entity-base-currency
        {
            # error: acquisition price asset code differs from
            # entity base currency
            die "Sorry, asset code for acquisition price differs
                    from entity base currency";
        }
    }
}

multi method perform-sanity-check(
    Hash[Hash[Hash[FatRat:D,PostingID:D],FatRat:D],AcctName:D]
        :%total-quantity-debited! is readonly,
    Hash[Quantity:D,Quantity:D] :%total-quantity-expended!,
)
{
    my Quantity $total-quantity-debited = %total-quantity-debited.keys[0];
    my Quantity $total-quantity-expended = %total-quantity-expended.keys[0];

    # verify that the sum total quantity being debited from
    # ASSETS wallets == the sum total quantity expended according
    # to Taxes{$tax-id}
    #
    # was the total quantity debited of asset code $asset-code in target
    # ASSETS wallets different from the total quantity expended
    # according to Taxes instances generated by EntryID $tax-id?
    #
    # they should always be equivalent
    unless $total-quantity-debited == $total-quantity-expended
    {
        # error: total quantity debited mismatch
        die "Sorry, encountered total quantity debited mismatch";
        # this suggests original Holding.EXPEND call calculation
        # of INCs - DECs contains a bug not caught in testing, or
        # that the above %acct-targets were grepped for using
        # flawed terms, or that Entity.get-total-quantity-debited
        # call to Wallet.ls-changesets produced unexpected results
    }
}

multi method perform-sanity-check(
    Array[Instruction:D] :%instructions!,
    EntryID:D :$tax-id!,
    Nightscape::Entity::Holding::Taxes:D :@taxes! is readonly
)
{
    # get original quantity debited value in entity base currency,
    # of asset code $asset-code in entry id $tax-id, that is,
    # the sum of balance deltas
    #
    # NOTE: it is crucial to only sum the value of postings
    #       rewritten by Instructions (%instructions.keys)
    my Quantity $original-value-debited =
        [+] (self.get-posting-value(
                :base-currency($.entity-base-currency),
                :entry-id($tax-id),
                :posting-id($_)
            ) for %instructions.keys);

    # get new quantity debited value in entity base currency,
    # of asset code $asset-code in EntryID $tax-id, from
    # Instructions
    my Quantity $new-value-debited;
    for %instructions.values -> @instructions
    {
        for @instructions -> $instruction
        {
            # all Instructions include quantity to debit
            my Quantity $quantity-to-debit =
                $instruction<quantity-to-debit>;

            # some MOD Instructions and all NEW Instructions
            # include xe
            my Quantity $xe;
            if $instruction<xe>
            {
                $xe = $instruction<xe>;
            }
            else
            {
                # find xe by backtracing to causal transaction
                my Nightscape::Entity::TXN $txn = self.ls-txn(
                    :posting-id($instruction<posting-id>)
                );
                my Nightscape::Entity::TXN::ModWallet @mod-wallets =
                    $txn.mod-wallet.grep({
                        .posting-id == $instruction<posting-id>
                    });
                unless @mod-wallets.elems == 1
                {
                    if @mod-wallets.elems > 1
                    {
                        die "Sorry, found more than one TXN.mod-wallet
                             with the same PostingID, which should
                             be impossible";
                    }
                    elsif @mod-wallets.elems < 1
                    {
                        die "Sorry, found no matching TXN.mod-wallet
                             with requested PostingID";
                    }
                }
                my Nightscape::Entity::TXN::ModWallet $mod-wallet =
                    @mod-wallets[0];
                $xe = $mod-wallet.xe-asset-quantity;
            }

            my Quantity $val = FatRat($quantity-to-debit * $xe);
            $new-value-debited += $val;
        }
    }

    # we expect NSAutoCapitalGains to change by this amount
    # if >0, realized capital gains, NSAutoCapitalGains++
    # if <0, realized capital losses, NSAutoCapitalGains--
    my FatRat $expected-income-delta =
        $original-value-debited - $new-value-debited;

    # the amount to change NSAutoCapitalGains by
    my FatRat $actual-income-delta =
        [+] (.capital-gains - .capital-losses for @taxes);

    # was expected income delta not the same as actual income
    # delta?
    unless $expected-income-delta == $actual-income-delta
    {
        # error: expectations differ from actual
        die "Sorry, expected income delta not equivalent to gains less losses";
    }
}

multi method perform-sanity-check(
    FatRat:D :$capital-gains!,
    FatRat:D :$capital-losses!
)
{
    if $capital-gains > 0
    {
        unless $capital-losses == 0
        {
            die "Sorry, unexpected capital losses in the
                presence of capital gains on a per tax
                event basis";
        }
    }
    elsif $capital-losses > 0
    {
        unless $capital-gains == 0
        {
            die "Sorry, unexpected capital gains in the
                presence of capital losses on a per tax
                event basis";
        }
    }
    else
    {
        # impossible for a single tax event to have
        # neither capital gains nor capital losses since
        # &Holding.expend::rmtargets generates Taxes.new per
        # each basis lot expended, computing gains or losses,
        # or no gains/losses, relative to each basis lot
        # being targeted:
        #
        # - an expenditure had to have happened to instantiate
        #   the Taxes class, creating those capital gains or
        #   losses with the associated EntryID (the 'taxes.keys')
        # - if (expend price - basis price) * quantity expended > 0,
        #   only then will a Taxes class be instantiated and
        #   realized capital gains recorded
        # - if (expend price - basis price) * quantity expended < 0,
        #   only then will a Taxes class be instantiated and
        #   realized capital losses recorded
        # - under no other conditions would the key $tax-id exist
        # - each single tax event will necessarily be either
        #   a gain or a loss
        die "Sorry, unexpected absence of capital gains and losses";
    }
}

# grep for wallet paths C<AcctName>s containing Wallet.balance
# adjustment events only of asset code $asset-code, and caused only
# by EntryID $tax-id leading to realized capital gains or realized
# capital losses
# - the changesets are not being returned, just the paths to wallets
#   containing those changesets (AcctName) and related info (Acct)
sub resolve-acct-targets(
    Nightscape::Entity::COA::Acct:D :%acct! is readonly,
    AssetCode:D :$asset-code!,
    EntryID:D :$tax-id!
) returns Hash[Nightscape::Entity::COA::Acct:D,AcctName:D]
{
    my Nightscape::Entity::COA::Acct:D %acct-targets{AcctName:D} = %acct.grep({
        # only find targets in Silo ASSETS
        .value.path[0] ~~ "ASSETS"
    }).grep({
        # only find targets with matching asset code and EntryID
        .value.entry-ids-by-asset{$asset-code} # empty wallets return Nil
            ?? .value.entry-ids-by-asset{$asset-code}.grep($tax-id)
            !! False;
    });
}

method gen-acct(
    Nightscape::Entity::Wallet:D :%wallet! is readonly
) returns Hash[Nightscape::Entity::COA::Acct:D,AcctName:D]
{
    my Array[VarName:D] @tree = self.tree(:%wallet);
    my Nightscape::Entity::COA::Acct:D %acct{AcctName:D} = self.tree2acct(
        :@tree,
        :%wallet
    );
}

# bucket with fill progress, incl. fills per acquisition price
class Bucket
{
    # containing acct (ownership, lookup path)
    has AcctName $.acct-name;

    # bucket max capacity
    has Quantity $.capacity = FatRat(0.0);

    # was bucket capacity artificially constrained by acct quantity
    # debited limits?
    has Bool $.constrained = False;

    # bucket's original, unconstrained capacity
    has Quantity $.unconstrained-capacity;

    # running total filled
    has Quantity $.filled = FatRat(0.0);

    # capacity less filled
    has Quantity $.open = $!capacity - $!filled;

    # causal PostingID
    has PostingID $.posting-id;

    # subfills indexed by acquisition price
    has Quantity %.subfills{Quantity};

    # add subfill to %.subfills at acquisition price (xe-asset-quantity)
    method mksubfill(
        Quantity:D :$acquisition-price!,    # price at acquisition (or avco)
        Quantity:D :$subfill!               # amount to fill at price
    )
    {
        # ensure bucket has capacity open for this subfill
        self!update-open;
        unless $subfill <= $.open
        {
            die "Sorry, cannot mksubfill, not enough capacity remaining";
        }
        %!subfills{$acquisition-price} = $subfill;
        self!update-filled;
        self!update-open;
    }

    # calculate bucket capacity less filled
    method !update-open()
    {
        $!open = $.capacity - $.filled;
    }

    # update $.filled, gets called after every subfill
    method !update-filled()
    {
        my Quantity $filled = FatRat(0.0);
        $filled += [+] %.subfills.values;
        $!filled = $filled;
    }
}

sub gen-buckets(
    Hash[Hash[Hash[FatRat:D,PostingID:D],FatRat:D],AcctName:D]
        :%total-quantity-debited! is readonly,
) returns Hash[Bucket:D,PostingID:D]
{
    my Bucket:D %buckets{PostingID:D};

    # (from data structure of %total-quantity-debited)
    # total quantity debited in targets, separately and in total
    #
    #     TotalQuantityDebited => %(
    #         TargetAcctName => %(
    #             TargetAcctBalanceDelta => %(
    #                 PostingID => PostingIDBalanceDelta,
    #                 PostingID => PostingIDBalanceDelta,
    #                 PostingID => PostingIDBalanceDelta
    #             )
    #         ),
    #         TargetAcctName => %(
    #             TargetAcctBalanceDelta => %(
    #                 PostingID => PostingIDBalanceDelta,
    #                 PostingID => PostingIDBalanceDelta,
    #                 PostingID => PostingIDBalanceDelta
    #             )
    #         )
    #     )
    #
    for %total-quantity-debited.values.list[0].hash.kv ->
        $target-acct-name, %target-acct-balance-delta
    {
        # filter out accts where no assets were debited
        # ($target-acct-balance-delta-sum >= 0)
        unless %target-acct-balance-delta.keys[0] < 0
        {
            next;
        }

        # for each %(TargetAcctBalanceDelta => Posting) pair where
        # TargetAcctBalanceDelta < 0:
        #
        #     TargetAcctBalanceDelta => %(
        #         PostingID => PostingIDBalanceDelta,
        #         PostingID => PostingIDBalanceDelta,
        #         PostingID => PostingIDBalanceDelta
        #     )
        #
        for %target-acct-balance-delta.kv ->
            $target-acct-balance-delta-sum, %balance-delta-by-posting-id
        {
            # store quantity remaining to debit of this TargetAcct
            # (TargetAcctBalanceDelta)
            #
            # must skip to new acct before overdebiting an acct with
            # realized capital gains / losses incision balacing strategy
            my Quantity $remaining-acct-debit-quantity =
                $target-acct-balance-delta-sum.abs;

            # instantiate one bucket per PostingID, only for those
            # postings with negative balance-delta
            #
            # we subdivide only these postings with asset outflows when incising
            # realized capital gains / losses

            # for all %(PostingID => PostingIDBalanceDelta) pairs with
            # Changeset.balance-delta less than zero
            my LessThanZero %bdbpu{PostingID} =
                %balance-delta-by-posting-id.grep({ .value < 0 });
            for %bdbpu.kv -> $posting-id, $balance-delta
            {
                # store capacity of Bucket
                my Quantity $capacity;

                # is bucket being constrained by acct quantity debited
                # limits?
                my Bool $constrained;

                # if constrained, what is the original unconstrained
                # capacity?
                my Quantity $unconstrained-capacity;

                # is this acct's remaining quantity debited greater than
                # or equal to PostingID's PostingIDBalanceDelta.abs?
                #
                # to make comparing easier, negate balance delta since
                # it is known to be < 0
                if $remaining-acct-debit-quantity >= -$balance-delta
                {
                    # instantiate Bucket with full capacity of its
                    # causal Changeset.balance-delta, since the quantity
                    # remaining to debit from this acct is greater than
                    # or equal to this number
                    $capacity = -$balance-delta;

                    # subtract capacity from remaining acct debit quantity
                    $remaining-acct-debit-quantity -= $capacity;
                }
                # is this acct's remaining quantity debited less than
                # the posting's quantity debited?
                elsif $remaining-acct-debit-quantity < -$balance-delta
                {
                    # special case: mark bucket as having artificially
                    # constrained capacity, and record its original
                    # capacity
                    $constrained = True;
                    $unconstrained-capacity = -$balance-delta;

                    # instantiate Bucket with partial capacity of its
                    # causal Changeset.balance-delta
                    #
                    # the transaction journal entry subacct net debited
                    # $target-acct-debit-quantity, and we don't want
                    # the postings made through this acct to contain
                    # holding basis lot quantities above the original
                    # net debited quantity
                    $capacity = $remaining-acct-debit-quantity;

                    # subtract capacity from remaining acct debit quantity
                    $remaining-acct-debit-quantity -= $capacity;
                }

                #
                # instantiate bucket, indexed by PostingID with:
                #
                # - capacity (of the amount expended in the acct per the Entry)
                #   - INCs less DECs to the asset in the original Entry
                #   - this is what the method Entity.get-total-quantity-debited
                #     does when it sums the balance delta of all changesets
                #     particular to an EntryID's handling of an asset,
                #     one with realized capital gains / losses
                # - PostingID
                #   - PostingID with a Changeset.balance-delta less
                #     than zero
                #     - if the summed balance-deltas are negative for an asset
                #       in a particular entry, at least one of the negative
                #       C<Entry::Posting>s had to be in part responsible for a
                #       holding basis lot expenditure
                #   - suitable for subdividing the balance delta into expended
                #     holding basis lots with differing XE if necessary
                #   - since the changesets are summed, it may not matter whether
                #     we subdivide a positive or a negative
                #     Changeset.balance-delta as the net result of summing
                #     either one should be equivalent
                #   - it's impossible to run out of buckets for an Entry's
                #     expenditures, because net outflows (expenditures) of an
                #     asset will always be less than or equal to the sum of the
                #     Entry's negative-only C<Changeset.balance-delta>s
                #     - paying the Bitcoin miners' fee during an asset transfer
                #       would be an example of an expenditure sized much less
                #       than the sum of the Entry's negative-only balance-deltas
                #     - example:
                #
                #     # asset transfer to cold storage
                #     2015-07-10 "I transferred BTC to cold storage"
                #       ASSETS:Personal:ColdStorage:Bread   23.999 BTC @ 300 USD
                #       ASSETS:Personal:ColdStorage:Paper   24 BTC @ 300 USD
                #       EXPENSES:Personal:MinersFee:BTC     0.001 BTC @ 300 USD
                #       ASSETS:Personal:BitBrokerA         -15 BTC @ 300 USD
                #       ASSETS:Personal:BitBrokerB         -15 BTC @ 300 USD
                #       ASSETS:Personal:BitBrokerC         -18 BTC @ 300 USD
                #
                #     # sum of Entry's C<Changeset.balance-delta>s affecting
                #     # ASSETS wallet and asset code BTC:
                #     #     = (23.999 + 24) - (15 + 15 + 18)
                #     #     = 47.999 - 48
                #     #     = -0.001
                #     #     # this is an expenditure with possible realized
                #     #     # capital gains / losses
                #     #
                #     # total quantity debited of asset (expenditure / outflow):
                #     #     = abs(-0.001)
                #     #     = 0.001
                #     #
                #     # sum of negative-only C<Changeset.balance-delta>s:
                #     #     = 15 + 15 + 18
                #     #     = 48
                #     #
                #     # we can pick BitBrokerA, BitBrokerB or BitBrokerC to
                #     # subdivide for incising realized capital gains / losses
                #     #
                #     # if the miners fee was 17 BTC, it would be possible to
                #     # subdivide the outflow of 18 first, but it doesn't
                #     # matter if the 18 outflow, the two 15 outflows, or one
                #     # 15 outflow and the 18 outflow are subdivided, or all
                #     # three
                #
                %buckets{$posting-id} = Bucket.new(
                    :acct-name($target-acct-name),
                    :$capacity,
                    :$constrained,
                    :$unconstrained-capacity,
                    :$posting-id
                );

                # is there no remaining quantity to debit in acct?
                unless $remaining-acct-debit-quantity > 0
                {
                    # go to next %(TargetAcctBalanceDelta => Posting)
                    # pair
                    last;
                }

                # default action:
                # go to next %(PostingID => PostingIDBalanceDelta)
                # pair where PostingIDBalanceDelta is less than zero,
                # as there is still some acct debit quantity remaining
            }
        }
    }

    %buckets;
}

sub fill-buckets(
    Bucket:D :%buckets!,
    Hash[Quantity:D,Quantity:D] :%total-quantity-expended! is readonly
)
{
    my Quantity $remaining-total-quantity-expended =
        %total-quantity-expended.keys[0];

    # for every subtotal quantity expended needing a bucket to call home
    # (at acquisition price), put each $subtotal-quantity-expended into
    # bucket until/unless full, then fill next bucket
    for %total-quantity-expended.values.list[0].hash.kv ->
        $acquisition-price, $subtotal-quantity-expended
    {
        # store remaining subtotal still needing to be disbursed to buckets
        my Quantity $remaining = $subtotal-quantity-expended;

        # does any portion of this subtotal still need to be disbursed?
        while $remaining > 0
        {
            # then disburse the remaining amount to buckets
            # - amounts are assigned to each bucket/acct at random,
            #   but for FIFO/LIFO/AVCO it is arbitrary which wallet
            #   spends which holdings at each price point expended

            # for each %(PostingID => Bucket) pair
            for %buckets.kv -> $posting-id, $bucket
            {
                # how much capacity in bucket is currently open?
                my Quantity $open = $bucket.open;

                # is there not any capacity remaining in this bucket?
                unless $open > 0
                {
                    # try next bucket
                    next;
                }

                # is the remaining amount greater than or equal to the
                # capacity of this bucket?
                if $remaining >= $open
                {
                    # take up the entire capacity of this bucket
                    $bucket.mksubfill(
                        :$acquisition-price,
                        :subfill($open)
                    );

                    # ensure this bucket has zero remaining capacity
                    unless $bucket.open == 0
                    {
                        die "Sorry, expected capacity of bucket to be
                            0 after subtracting the amount open
                            「$open」";
                    }

                    # subtract $open from $remaining, ensuring we have
                    # $open less to disburse
                    $remaining-total-quantity-expended -= $open;
                    $remaining -= $open;

                    # if remaining was disbursed in full due to bucket's
                    # large capacity, break from this original subtotal
                    # quantity lot needing a bucket to call home at
                    # acquisition price, no more of it is remaining
                    $remaining == 0 ?? (last) !! (next);
                }
                # is the remaining amount less than the capacity of
                # this bucket?
                elsif $remaining < $open
                {
                    # take up just the amount needed in this bucket
                    $bucket.mksubfill(
                        :$acquisition-price,
                        :subfill($remaining)
                    );

                    # ensure $remaining less $remaining is 0
                    $remaining-total-quantity-expended -= $remaining;
                    $remaining -= $remaining;

                    # break from this original subtotal quantity lot needing
                    # a bucket to call home at acquisition price, no more
                    # of it is remaining
                    last;
                }
            }
        }
    }

    # is there not zero remaining of total quantity expended?
    unless $remaining-total-quantity-expended == 0
    {
        # error: total quantity expended failed to be reassigned in full
        die "Sorry, expected remaining total quantity expended to be zero";
    }
}

sub buckets2instructions(
    Bucket:D :%buckets
) returns Hash[Array[Instruction:D],PostingID:D]
{
    # store lists of instructions indexed by causal PostingID
    my Array[Instruction:D] %instructions{PostingID:D};

    # foreach %(PostingID => Bucket) pair
    for %buckets.kv -> $posting-id, $bucket
    {
        # store list of instructions generated from bucket
        my Instruction:D @instructions;

        # store bucket's parent acct name, which is the subject of
        # PostingID
        my AcctName $acct-name = $bucket.acct-name;

        # was bucket capacity artificially constrained by acct debit
        # quantity limits?
        if $bucket.constrained
        {
            # what was bucket causal posting's unconstrained capacity?
            my Quantity $unconstrained-capacity =
                $bucket.unconstrained-capacity;

            # what was bucket capacity forced down to?
            my Quantity $capacity = $bucket.capacity;

            # how much of the bucket's forced capacity is filled?
            my Quantity $filled = $bucket.filled;

            # how much of the bucket's forced capacity is open?
            my Quantity $open-constrained = $capacity - $filled;

            # open total is the sum of the bucket's constrained space
            # open and its original, unconstrained capacity less the
            # constrained capacity
            #
            # The Special Case of a Constrained Bucket
            # ----------------------------------------
            #
            #     ┏━━━━━━━━━━━━━━━━━┓ <------- $unconstrained-capacity
            #     ┃                 ┃
            #     ┃                 ┃
            #     ┃                 ┃
            #     ┃                 ┃
            #     ┃                 ┃
            #     ┃                 ┃
            #     ┃─────────────────┃ <------- $capacity
            #     ┃                 ┃
            #     ┃┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┃ <------- $open-constrained
            #     ┃                 ┃
            #     ┗━━━━━━━━━━━━━━━━━┛
            #
            # open total is the MOD Instruction's quantity-to-debit
            my Quantity $open-total =
                $open-constrained + ($unconstrained-capacity - $capacity);

            # is open total not greater than zero?
            #
            # open total should always be greater than zero, since the
            # bucket would not have a constrained capacity in the first
            # place if it weren't for the unconstrained capacity exceeding
            # remaining acct debit quantity
            unless $open-total > 0
            {
                # error: unexpected open total
                die "Sorry, unexpected open total";
            }

            # set orig bucket = special case open total
            {
                my NewMod $newmod = MOD;
                my Quantity $quantity-to-debit = $open-total;
                my Quantity $xe = Nil;
                my Instruction $instruction = {
                    :$acct-name,
                    :$newmod,
                    :$posting-id,
                    :$quantity-to-debit,
                    :$xe
                };
                push @instructions, $instruction;
            }

            # create one more bucket foreach $bucket.subfills.keys[0..*]
            for $bucket.subfills.kv -> $acquisition-price, $quantity-to-debit
            {
                my NewMod $newmod = NEW;
                my Quantity $xe = $acquisition-price;
                my Instruction $instruction = {
                    :$acct-name,
                    :$newmod,
                    :$posting-id,
                    :$quantity-to-debit,
                    :$xe
                };
                push @instructions, $instruction;
            }
        }
        # does bucket have capacity remaining?
        elsif $bucket.open
        {
            # set orig bucket = open size
            {
                my NewMod $newmod = MOD;
                my Quantity $quantity-to-debit = $bucket.open;
                my Quantity $xe = Nil;
                my Instruction $instruction = {
                    :$acct-name,
                    :$newmod,
                    :$posting-id,
                    :$quantity-to-debit,
                    :$xe
                };
                push @instructions, $instruction;
            }

            # create one more bucket foreach $bucket.subfills.keys[0..*]
            for $bucket.subfills.kv -> $acquisition-price, $quantity-to-debit
            {
                my NewMod $newmod = NEW;
                my Quantity $xe = $acquisition-price;
                my Instruction $instruction = {
                    :$acct-name,
                    :$newmod,
                    :$posting-id,
                    :$quantity-to-debit,
                    :$xe
                };
                push @instructions, $instruction;
            }
        }
        # bucket has none of its capacity remaining
        else
        {
            # set orig bucket = $bucket.subfills.keys[0]
            {
                my NewMod $newmod = MOD;
                my Quantity $quantity-to-debit = $bucket.subfills.values[0];
                my Quantity $xe = $bucket.subfills.keys[0];
                my Instruction $instruction = {
                    :$acct-name,
                    :$newmod,
                    :$posting-id,
                    :$quantity-to-debit,
                    :$xe
                };
                push @instructions, $instruction;
            }

            # create one more bucket foreach $bucket.subfills.keys[1..*]
            loop (my Int $i = 1; $i < $bucket.subfills.elems; $i++)
            {
                my NewMod $newmod = NEW;
                my Quantity $quantity-to-debit = $bucket.subfills.values[$i];
                my Quantity $xe = $bucket.subfills.keys[$i];
                my Instruction $instruction = {
                    :$acct-name,
                    :$newmod,
                    :$posting-id,
                    :$quantity-to-debit,
                    :$xe
                };
                push @instructions, $instruction;
            }
        }

        push %instructions{$posting-id}, |@instructions;
    }

    %instructions;
}

# return instructions for incising realized capital gains / losses
# indexed by causal posting-id (NEW/MOD | AcctName | QuantityToDebit | XE)
sub gen-instructions(
    Hash[Hash[Hash[FatRat:D,PostingID:D],FatRat:D],AcctName:D]
        :%total-quantity-debited! is readonly,
    Hash[Quantity:D,Quantity:D] :%total-quantity-expended! is readonly
) returns Hash[Array[Instruction:D],PostingID:D]
{
    # make buckets containing amounts needing to be filled in
    # Entity.wallet, indexed by PostingID, %(PostingID => Bucket)
    my Bucket:D %buckets{PostingID:D} = gen-buckets(:%total-quantity-debited);

    # fill buckets based on total quantity expended
    fill-buckets(:%buckets, :%total-quantity-expended);

    # convert %buckets to instructions
    my Array[Instruction:D] %instructions{PostingID:D} = buckets2instructions(
        :%buckets
    );
}

# given entry, return instantiated transaction
method gen-txn(
    Nightscape::Entry:D :$entry! is readonly
) returns Nightscape::Entity::TXN:D
{
    # verify entry is balanced or exit with an error
    unless $entry.is-balanced
    {
        say "Sorry, cannot gen-txn: entry not balanced.";
        die X::Nightscape::Entry::NotBalanced.new(:entry-id($entry.id));
    }

    # source EntryID
    my EntryID $entry-id = $entry.id;

    # transaction data storage
    my Nightscape::Entity::TXN::ModHolding %mod-holdings{AssetCode};
    my Nightscape::Entity::TXN::ModWallet @mod-wallet;

    # build mod-wallet for dec/inc applicable wallet balance
    for $entry.postings -> $posting
    {
        # from Nightscape::Entry::Posting
        my PostingID $posting-id = $posting.id;
        my Nightscape::Entry::Posting::Account $account = $posting.account;
        my Nightscape::Entry::Posting::Amount $amount = $posting.amount;
        my DecInc $decinc = $posting.decinc;

        # from Nightscape::Entry::Posting::Account
        my Silo $silo = $account.silo;
        my VarName @subwallet = $account.subaccount;

        # from Nightscape::Entry::Posting::Amount
        my AssetCode $asset-code = $amount.asset-code;
        my Quantity $quantity = $amount.asset-quantity;

        # from Nightscape::Entry::Posting::Amount::XE
        my AssetCode $xe-asset-code;
        $xe-asset-code = try {$amount.exchange-rate.asset-code};
        my Quantity $xe-asset-quantity;
        $xe-asset-quantity = try {$amount.exchange-rate.asset-quantity};

        # build mod-wallet
        push @mod-wallet, Nightscape::Entity::TXN::ModWallet.new(
            :entity($.entity-name),
            :$entry-id,
            :$posting-id,
            :$asset-code,
            :$decinc,
            :$quantity,
            :$silo,
            :@subwallet,
            :$xe-asset-code,
            :$xe-asset-quantity
        );
    }

    # build mod-holdings for acquire/expend the applicable holdings

    # find entry postings affecting silo ASSETS
    my Silo $silo = ASSETS;
    my Nightscape::Entry::Posting @postings = $entry.postings;
    my Nightscape::Entry::Posting @postings-assets-silo =
        Nightscape::Entry.ls-postings(:@postings, :$silo);

    my AssetCode $entity-base-currency = $.entity-base-currency;
    my Regex $asset-code = /$entity-base-currency/;
    my Nightscape::Entry::Posting @postings-assets-silo-base-currency =
        Nightscape::Entry.ls-postings(:@postings, :$asset-code, :$silo);

    # filter out base currency postings
    my Nightscape::Entry::Posting @postings-remainder =
        (@postings-assets-silo (-) @postings-assets-silo-base-currency).keys;

    # find unique aux asset codes
    my AssetCode @aux-asset-codes = Nightscape::Entry.ls-asset-codes(
        :postings(@postings-remainder)
    );

    # calculate difference between INCs and DECs for each aux asset code
    for @aux-asset-codes -> $aux-asset-code
    {
        # filter for postings only of this asset code
        my Nightscape::Entry::Posting @p = Nightscape::Entry.ls-postings(
            :postings(@postings-remainder),
            :asset-code(/$aux-asset-code/)
        );

        # sum INCs
        my Nightscape::Entry::Posting @p-inc = @p.grep({ .decinc ~~ INC });
        my FatRat $incs = FatRat([+] (.amount.asset-quantity for @p-inc));

        # sum DECs
        my Nightscape::Entry::Posting @p-dec = @p.grep({ .decinc ~~ DEC });
        my FatRat $decs = FatRat([+] (.amount.asset-quantity for @p-dec));

        # INCs - DECs
        my FatRat $d = $incs - $decs;

        # asset flow: acquire / expend
        my AssetFlow $asset-flow = mkasset-flow($d);

        # asset quantity
        my Quantity $quantity = $d.abs;

        # asset costing method
        my Costing $costing = $GLOBAL::CONF.resolve-costing(
            :asset-code($aux-asset-code),
            :$.entity-name
        );

        # prepare cost basis data
        my DateTime $date = $entry.header.date;
        my Price $price = @p[0].amount.exchange-rate.asset-quantity;
        my AssetCode $acquisition-price-asset-code =
            @p[0].amount.exchange-rate.asset-code;

        # build mod-holdings
        %mod-holdings{$aux-asset-code} =
            Nightscape::Entity::TXN::ModHolding.new(
                :entity($.entity-name),
                :asset-code($aux-asset-code),
                :$asset-flow,
                :$costing,
                :$date,
                :$price,
                :$acquisition-price-asset-code,
                :$quantity
            );
    }

    # build transaction
    Nightscape::Entity::TXN.new(
        :entity($.entity-name),
        :$entry-id,
        :%mod-holdings,
        :@mod-wallet
    );
}

# get balance of each asset present in wallet %wallet Silo Assets
method get-balance(
    Nightscape::Entity::Wallet:D :%wallet! is readonly
) returns Hash[FatRat,AssetCode]
{
    my FatRat %balance{AssetCode};
    my AssetCode @assets-handled = self.ls-assets-handled(:%wallet);
    for @assets-handled -> $asset-code
    {
        %balance{$asset-code} = self.get-balance-by-asset(
            :$asset-code,
            :%wallet
        );
    }
    %balance;
}

# get balance of asset $asset-code in wallet %wallet Silo Assets
method get-balance-by-asset(
    AssetCode:D :$asset-code!,
    Nightscape::Entity::Wallet:D :%wallet! is readonly,
) returns FatRat
{
    my AssetCode $base-currency; # purposefully empty var
    my FatRat $balance = in-wallet(%wallet{ASSETS}).get-balance(
        :$asset-code,
        :$base-currency,
        :recursive
    );
}

# recursively sum balances in terms of entity base currency,
# all wallets in all Silos
method get-eqbal(
    Nightscape::Entity::Wallet:D :%wallet! is readonly,
    Nightscape::Entity::COA::Acct :%acct is readonly
) returns Hash[FatRat:D,Silo:D]
{
    # assets handled, from COA::Acct if %acct was passed, falling back
    # to the COA::Acct generated from Wallet if COA::Acct was not passed
    my AssetCode @assets-handled =
        %acct ?? self.ls-assets-handled(:%acct)
              !! self.ls-assets-handled(:%wallet);

    # store total sum FatRat balance indexed by Silo
    my FatRat:D %balance{Silo:D};

    # sum wallet balances and store in %balance
    sub fill-balance(AssetCode:D $asset-code)
    {
        # for all wallets in all Silos
        for Silo.enums.keys -> $silo
        {
            # adjust Silo wallet's running balance (in entity's base currency)
            %balance{::($silo)} += in-wallet(%wallet{::($silo)}).get-balance(
                :$asset-code,
                :base-currency($.entity-base-currency),
                :recursive
            );
        }
    }

    # calculate %balance for all assets handled by this entity
    fill-balance($_) for @assets-handled;

    %balance;
}

method get-posting-value(
    AssetCode:D :$base-currency!,
    EntryID:D :$entry-id!,
    PostingID:D :$posting-id!
) returns Quantity:D
{
    my Quantity $posting-value;
    my Nightscape::Entity::TXN $txn = self.ls-txn(:$entry-id);
    $txn.mod-wallet.grep({ .posting-id == $posting-id }).map({
        unless .xe-asset-code ~~ $base-currency
        {
            die "Sorry, unexpected xe-asset-code";
        };
        $posting-value += .quantity * .xe-asset-quantity
    });

    $posting-value;
}

multi method perform-sanity-check(
    Quantity :$target-acct-debit-quantity!,
    Quantity :$target-acct-credit-quantity!
)
{
    if $target-acct-debit-quantity
    {
        unless $target-acct-credit-quantity == 0
        {
            die "Sorry, unexpected presence of target acct credits when
                 debits are present";
        }
    }
    elsif $target-acct-credit-quantity
    {
        unless $target-acct-debit-quantity == 0
        {
            die "Sorry, unexpected presence of target acct debits when
                 credits are present";
        }
    }
}

# get quantity debited in targets, separately and in total
method !get-total-quantity-debited(
    Nightscape::Entity::COA::Acct:D :%acct-targets! is readonly,
    AssetCode:D :$asset-code!,
    EntryID:D :$entry-id!,
    Nightscape::Entity::Wallet:D :%wallet! is readonly
) returns Hash[Hash[Hash[Hash[FatRat:D,PostingID:D],FatRat:D],AcctName:D],Quantity:D]
{
    # store subtotal quantity debited
    my Quantity $subtotal-quantity-debited;

    # store subtotal quantity credited
    my Quantity $subtotal-quantity-credited;

    # store Changeset.balance-delta indexed by PostingID, indexed by
    # subtotal quantity debited in the acct (the sum of balance deltas
    # one per posting), indexed by acct name:
    #
    #     TargetAcctName => %(
    #         TargetAcctBalanceDelta => %(
    #             PostingID => PostingIDBalanceDelta,
    #             PostingID => PostingIDBalanceDelta,
    #             PostingID => PostingIDBalanceDelta
    #         )
    #     ),
    #     TargetAcctName => %(
    #         TargetAcctBalanceDelta => %(
    #             PostingID => PostingIDBalanceDelta,
    #             PostingID => PostingIDBalanceDelta,
    #             PostingID => PostingIDBalanceDelta
    #         )
    #     )
    #
    #  -------
    #
    #  $total-quantity-debited = [+] (.TargetAcctBalanceDelta for TargetAcctName)
    #
    my Hash[Hash[FatRat:D,PostingID:D],FatRat:D]
        %total-balance-delta-per-acct{AcctName:D};

    # for each target acct
    for %acct-targets.kv -> $acct-name, $acct
    {
        # get all those changesets in acct affecting only asset code
        # $asset-code, and sharing EntryID $entry-id
        my Nightscape::Entity::Wallet::Changeset @changesets =
            in-wallet(%wallet{::($acct.path[0])}, $acct.path[1..*]).ls-changesets(
                :$asset-code,
                :$entry-id
            );

        # were there no matching changesets found?
        unless @changesets.elems > 0
        {
            # error: unexpected no match for changesets
            die "Sorry, expected at least one changeset, but none were found";
        }

        # stores each changeset's debit quantity, indexed by PostingID
        #
        #     %(
        #         PostingID => PostingIDBalanceDelta,
        #         PostingID => PostingIDBalanceDelta,
        #         PostingID => PostingIDBalanceDelta
        #     )
        #
        my FatRat:D %balance-delta-by-posting-id{PostingID:D};

        # for all those changesets in acct affecting only asset code $asset-code,
        # and sharing EntryID $entry-id
        for @changesets -> $changeset
        {
            # causal PostingID, for precise changeset lookups
            my PostingID $posting-id = $changeset.posting-id;

            # causal posting's balance adjustment, for summing
            my FatRat $posting-id-balance-delta = $changeset.balance-delta;

            # changeset's debit quantity, indexed by PostingID
            %balance-delta-by-posting-id{$posting-id} =
                $posting-id-balance-delta;
        }

        # sum posting balance deltas, should be less than zero,
        # representing net expenditure/outflow of asset from silo
        # ASSETS wallet
        my FatRat $target-acct-balance-delta-sum =
            [+] %balance-delta-by-posting-id.values;

        # store this target acct's debits to asset
        my Quantity $target-acct-debit-quantity = FatRat(0.0);

        # store this target acct's credits to asset
        my Quantity $target-acct-credit-quantity = FatRat(0.0);

        # is sum of target acct's balance deltas less than zero?
        if $target-acct-balance-delta-sum < 0
        {
            # since we're sure the delta sum is less than zero, take
            # absolute value to get target acct debit quantity
            $target-acct-debit-quantity = $target-acct-balance-delta-sum.abs;
        }
        # is sum of target acct's balance deltas greater than zero?
        elsif $target-acct-balance-delta-sum > 0
        {
            # since we're sure the delta sum is greater than zero,
            # this is a credit
            $target-acct-credit-quantity = $target-acct-balance-delta-sum;
        }

        # ensure only one of target acct credit quantity or debit quantity
        # is > 0
        self.perform-sanity-check(
            :$target-acct-debit-quantity,
            :$target-acct-credit-quantity
        );

        # the intuitive version doesn't work
        #     %total-balance-delta-per-acct{$acct.name} =
        #         $target-acct-balance-delta-sum =>
        #             $%balance-delta-by-posting-id;
        #
        # helper:
        my Hash[FatRat:D,PostingID:D] %target-acct-balance-delta{FatRat:D} =
            $target-acct-balance-delta-sum => $%balance-delta-by-posting-id;
        %total-balance-delta-per-acct{$acct-name} = $%target-acct-balance-delta;

        # add subtotal balance delta to total quantity debited / credited
        # as appropriate
        $subtotal-quantity-debited += $target-acct-debit-quantity;
        $subtotal-quantity-credited += $target-acct-credit-quantity;
    }

    # store total quantity debited (subtotal quantity debited less
    # subtotal quantity credited)
    my GreaterThanZero:D $total-quantity-debited =
        $subtotal-quantity-debited - $subtotal-quantity-credited;

    # TotalQuantityDebited => %(
    #     TargetAcctName => %(
    #         TargetAcctBalanceDelta => %(
    #             PostingID => PostingIDBalanceDelta,
    #             PostingID => PostingIDBalanceDelta,
    #             PostingID => PostingIDBalanceDelta
    #         )
    #     ),
    #     TargetAcctName => %(
    #         TargetAcctBalanceDelta => %(
    #             PostingID => PostingIDBalanceDelta,
    #             PostingID => PostingIDBalanceDelta,
    #             PostingID => PostingIDBalanceDelta
    #         )
    #     )
    # )
    #
    # TotalQuantityDebited ------------------------------------------------------------------+
    # TargetAcctName ------------------------------------+                                   |
    # TargetAcctBalanceDelta ------------------+         |                                   |
    # PostingID -------------------+           |         |                                   |
    # PostingIDBalanceDelta        |           |         |                                   |
    #                    |         |           |         |                                   |
    #                    |         |           |         |                                   |
    my Hash[Hash[Hash[FatRat:D,PostingID:D],FatRat:D],AcctName:D] %total-quantity-debited{Quantity:D} =
        $total-quantity-debited => %total-balance-delta-per-acct;
}

# get quantity expended of a holding indexed by acquisition price,
# indexed by total quantity expended
sub get-total-quantity-expended(
    Costing:D :$costing!,
    Nightscape::Entity::Holding::Taxes:D :@taxes! is readonly
) returns Hash[Hash[Quantity:D,Quantity:D],Quantity:D]
{
    # store total quantity expended
    my Hash[Quantity:D,Quantity:D] %total-quantity-expended{Quantity:D};
    my Quantity:D $total-quantity-expended = FatRat(0.0);
    my Quantity:D %per-basis-lot{Quantity:D};

    # foreach tax event
    for @taxes -> $tax-event
    {
        # get subtotal quantity expended, and add to total
        my Quantity:D $subtotal-quantity-expended =
            $tax-event.quantity-expended;
        $total-quantity-expended += $subtotal-quantity-expended;

        # store acquisition price / avco for this tax id
        my Quantity:D $xe-asset-quantity = FatRat(0.0);

        # AVCO costing method?
        if $costing ~~ AVCO
        {
            # retrieve avco at expenditure of holding expended
            $xe-asset-quantity = $tax-event.avco-at-expenditure;
        }
        # FIFO/LIFO costing method?
        elsif $costing ~~ FIFO or $costing ~~ LIFO
        {
            # retrieve acquisition price of holding expended
            $xe-asset-quantity = $tax-event.acquisition-price;
        }

        # record acquisition price => subtotal quantity expended key-value pair
        # in %per-basis-lot
        %per-basis-lot{$xe-asset-quantity} += $subtotal-quantity-expended;
    }

    %total-quantity-expended = $total-quantity-expended => $%per-basis-lot;
}

# given a wallet, and subwallet name list, return scalar container of
# the deepest subwallet
#
# has harmless side effect of creating new and often empty Wallet classes
sub in-wallet(Nightscape::Entity::Wallet $wallet, *@subwallet) is rw
{
    # make $subwallet point to the same scalar container as $wallet
    my Nightscape::Entity::Wallet $subwallet := $wallet;

    # the subwallet name list
    my VarName @s = @subwallet;

    # if subwallets were given, loop through them
    while @s
    {
        # name of next deeper subwallet
        my VarName $s = @s.shift;

        # create $s if it doesn't exist
        unless $subwallet.subwallet{$s}
        {
            $subwallet.subwallet{$s} = Nightscape::Entity::Wallet.new;
        }

        # make $subwallet point to same scalar container as its subwallet, $s
        $subwallet := $subwallet.subwallet{$s};
    }

    # deepest subwallet
    $subwallet;
}

# list all unique asset codes handled by entity
multi method ls-assets-handled(
    Nightscape::Entity::COA::Acct:D :%acct! is readonly
) returns Array[AssetCode:D]
{
    # store assets handled by entity
    my AssetCode:D @assets-handled;

    # for all accts
    for %acct.kv -> $acct-name, $acct
    {
        # record assets handled in this acct
        push @assets-handled, |$acct.assets-handled;
    }

    @assets-handled .= unique;
}

multi method ls-assets-handled(
    Nightscape::Entity::Wallet:D :%wallet! is readonly
) returns Array[AssetCode:D]
{
    # generate acct from %wallet
    my Nightscape::Entity::COA::Acct %acct{AcctName} = self.gen-acct(:%wallet);

    # store assets handled by entity
    my AssetCode:D @assets-handled = self.ls-assets-handled(:%acct);
}

multi method ls-txn(EntryID:D :$entry-id!) returns Nightscape::Entity::TXN:D
{
    my Nightscape::Entity::TXN @txn = @.transactions.grep({
        .entry-id == $entry-id
    });
    unless @txn.elems == 1
    {
        if @txn.elems > 1
        {
            die "Sorry, found more matching transactions than expected";
        }
        elsif @txn.elems < 1
        {
            die "Sorry, couldn't find matching transaction";
        }
    }
    my Nightscape::Entity::TXN $txn = @txn[0];
}

multi method ls-txn(PostingID:D :$posting-id!) returns Nightscape::Entity::TXN:D
{
    my Nightscape::Entity::TXN @txn = @.transactions.grep({
        .mod-wallet».posting-id.grep($posting-id)
    });
    unless @txn.elems == 1
    {
        if @txn.elems > 1
        {
            die "Sorry, found more matching transactions than expected";
        }
        elsif @txn.elems < 1
        {
            die "Sorry, couldn't find matching transaction";
        }
    }
    my Nightscape::Entity::TXN $txn = @txn[0];
}

# instantiate entity's chart of accounts
method mkcoa(Bool :$force)
{
    # generate acct from %.wallet
    my Nightscape::Entity::COA::Acct %acct{AcctName} = self.gen-acct(:%.wallet);

    # find entries with realized capital gains / realized capital losses
    # use %.acct to find target list with wallet path
    my Nightscape::Entity::Wallet %wllt{Silo} = self.acct2wllt(:%acct);

    # instantiate entity's chart of accounts
    sub init()
    {
        $!coa = Nightscape::Entity::COA.new(:%acct, :%wllt);
    }

    # force instantiate new chart of accounts?
    if $force
    {
        # instantiate entity's chart of accounts
        init();
    }
    # does chart of accounts exist?
    elsif $.coa
    {
        # error: coa exists, pass arg :force to overwrite
        die "Sorry, cannot create COA self.coa: self.coa exists";
    }
    else
    {
        # chart of accounts does not exist, instantiate coa
        init();
    }
}

# instantiate TXN and append to entity's transactions queue
method mktxn(Nightscape::Entry:D $entry is readonly)
{
    push @!transactions, self.gen-txn(:$entry);
}

# acquire/expend the applicable holdings
method !mod-holdings(
    EntryID:D :$entry-id!,
    AssetCode:D :$asset-code!,
    AssetFlow:D :$asset-flow!,
    Costing:D :$costing!,
    DateTime:D :$date!,
    Price:D :$price!,
    AssetCode:D :$acquisition-price-asset-code!,
    Quantity:D :$quantity!
)
{
    # acquisition?
    if $asset-flow ~~ ACQUIRE
    {
        # instantiate holding if needed
        unless %.holdings{$asset-code}
        {
            %!holdings{$asset-code} = Nightscape::Entity::Holding.new(
                :$asset-code
            );
        }

        # acquire asset
        %!holdings{$asset-code}.acquire(
            :$entry-id,
            :$date,
            :$price,
            :$acquisition-price-asset-code,
            :$quantity
        );
    }
    # expenditure?
    elsif $asset-flow ~~ EXPEND
    {
        # if holding does not exist, exit with an error
        unless %.holdings{$asset-code}
        {
            say "Sorry, no holding exists of asset code 「$asset-code」.";
            die X::Nightscape::Entry.new(:$entry-id);
        }

        # check for sufficient unit quantity of asset in holdings
        my Quantity $quantity-held = %.holdings{$asset-code}.get-total-quantity;
        unless $quantity-held >= $quantity
        {
            say qq:to/EOF/;
            Sorry, cannot mod-holdings.expend: found insufficient quantity
            of asset 「$asset-code」 in holdings.

            Units needed of $asset-code: 「$quantity」
            Units held of $asset-code: 「$quantity-held」
            EOF
            die X::Nightscape::Entry.new(:$entry-id);
        }

        # expend asset
        %!holdings{$asset-code}.expend(
            :$entry-id,
            :$date,
            :$asset-code,
            :$costing,
            :$price,
            :$acquisition-price-asset-code,
            :$quantity
        );
    }
    # stable?
    elsif $asset-flow ~~ STABLE
    {
        # no change, likely an intra-entity asset transfer
    }
}

# dec/inc the applicable wallet balance
method !mod-wallet(
    EntryID:D :$entry-id!,
    PostingID:D :$posting-id!,
    AssetCode:D :$asset-code!,
    DecInc:D :$decinc!,
    Quantity:D :$quantity!,
    Silo:D :$silo!,
    Str :@subwallet, # When typecheck: VarName => Constraint type check failed for parameter '@subwallet'
    AssetCode :$xe-asset-code,
    Quantity :$xe-asset-quantity
)
{
    # ensure $silo wallet exists (potential side effect)
    unless %.wallet{$silo}
    {
        %!wallet{$silo} = Nightscape::Entity::Wallet.new;
    }

    # dec/inc wallet balance (potential side effect from in-wallet)
    in-wallet(%!wallet{$silo}, @subwallet).mkchangeset(
        :$entry-id,
        :$posting-id,
        :$asset-code,
        :$decinc,
        :$quantity,
        :$xe-asset-code,
        :$xe-asset-quantity
    );
}

# execute transaction
method transact(Nightscape::Entity::TXN:D $transaction is readonly)
{
    # causal transaction journal EntryID
    my EntryID $entry-id = $transaction.entry-id;

    # mod holdings (only needed for entries dealing in aux assets)
    my Nightscape::Entity::TXN::ModHolding %mod-holdings{AssetCode} =
        $transaction.mod-holdings;

    if %mod-holdings
    {
        for %mod-holdings.kv -> $asset-code, $mod-holding
        {
            my AssetFlow $asset-flow = $mod-holding.asset-flow;
            my Costing $costing = $mod-holding.costing;
            my DateTime $date = $mod-holding.date;
            my Price $price = $mod-holding.price;
            my AssetCode $acquisition-price-asset-code =
                $mod-holding.acquisition-price-asset-code;
            my Quantity $quantity = $mod-holding.quantity;

            self!mod-holdings(
                :$entry-id,
                :$asset-code,
                :$asset-flow,
                :$costing,
                :$date,
                :$price,
                :$acquisition-price-asset-code,
                :$quantity
            );
        }
    }

    # mod wallet balances
    my Nightscape::Entity::TXN::ModWallet @mod-wallet = $transaction.mod-wallet;
    for @mod-wallet -> $mod-wallet
    {
        my PostingID $posting-id = $mod-wallet.posting-id;
        my AssetCode $asset-code = $mod-wallet.asset-code;
        my DecInc $decinc = $mod-wallet.decinc;
        my Quantity $quantity = $mod-wallet.quantity;
        my Silo $silo = $mod-wallet.silo;
        my VarName @subwallet;
        @subwallet = $mod-wallet.subwallet if $mod-wallet.subwallet;
        my AssetCode $xe-asset-code;
        $xe-asset-code = try {$mod-wallet.xe-asset-code};
        my Quantity $xe-asset-quantity;
        $xe-asset-quantity = try {$mod-wallet.xe-asset-quantity};

        self!mod-wallet(
            :$entry-id,
            :$posting-id,
            :$asset-code,
            :$decinc,
            :$quantity,
            :$silo,
            :@subwallet,
            :$xe-asset-code,
            :$xe-asset-quantity
        );
    }
}

# list wallet tree recursively
method tree(
    Nightscape::Entity::Wallet:D :%wallet! is readonly,
    Silo :$silo,
    *@subwallet
) returns Array[Array[VarName:D]]
{
    # store wallet tree
    my Array[VarName:D] @tree;

    # was $silo arg specified?
    if defined $silo
    {
        # fill tree
        @tree = Nightscape::Entity::Wallet.tree(
            in-wallet(%wallet{$silo}, @subwallet).tree(:hash)
        );

        # prepend Silo to tree branches
        .unshift(~$silo) for @tree;

        # insert root Silo wallet
        {
            my VarName:D @root-silo-wallet = ~$silo;
            @tree.unshift: @root-silo-wallet;
        }
    }
    else
    {
        # assume all Silos were requested
        push @tree, |self.tree(:%wallet, :silo(::($_)), @subwallet)
            for Silo.enums.keys;
    }

    # return sorted tree
    @tree .= sort;
}

# given wallet tree, generate hash of accts, indexed by acct name
method tree2acct(
    Array[VarName:D] :@tree!,
    Nightscape::Entity::Wallet:D :%wallet! is readonly
) returns Hash[Nightscape::Entity::COA::Acct:D,AcctName:D]
{
    # store accts indexed by acct name
    my Nightscape::Entity::COA::Acct:D %acct{AcctName:D};

    # for every acct
    for @tree -> @path
    {
        # store acct name
        my AcctName $name = @path.join(':');

        # root Silo wallet
        my Nightscape::Entity::Wallet $wallet = %wallet{::(@path[0])};

        # store all assets handled
        my AssetCode @assets-handled =
            in-wallet($wallet, @path[1..*]).ls-assets;

        # store EntryIDs handled, indexed by asset code
        my Array[EntryID:D] %entry-ids-by-asset{AssetCode:D} =
            in-wallet($wallet, @path[1..*]).ls-assets-with-ids;

        # store PostingIDs handled, indexed by asset code
        my Array[PostingID] %posting-ids-by-asset{AssetCode:D} =
            in-wallet($wallet, @path[1..*]).ls-assets-with-ids(:posting);

        # store all EntryIDs handled
        my EntryID:D @entry-ids-handled =
            in-wallet($wallet, @path[1..*]).ls-ids;

        # store all PostingIDs handled
        my PostingID @posting-ids-handled =
            in-wallet($wallet, @path[1..*]).ls-ids(:posting);

        # instantiate acct
        %acct{$name} = Nightscape::Entity::COA::Acct.new(
            :$name,
            :@path,
            :@assets-handled,
            :%entry-ids-by-asset,
            :@entry-ids-handled,
            :%posting-ids-by-asset,
            :@posting-ids-handled
        );
    }

    %acct;
}

#
# --------------------
# Entity.acct2wllt doc
# --------------------
#
# - there is a list of realized capital gains / losses from each
#   EntryID
# - list is needed because a larger expenditure in the transaction
#   journal can deplete multiple asset (holding) basis lots, which
#   were acquired under unique exchange rates
# - example:
#
#     # asset acquisition in transaction journal entry
#     2010-01-11 "I bought 15 BTC at a price of $0.10 USD/BTC"
#       ASSETS:Personal:BitBrokerA            15 BTC @ 0.1 USD
#       ASSETS:Personal:Bankwest:Cheque      -1.50 USD
#
#     2010-01-12 "I bought 15 BTC at a price of $0.20 USD/BTC"
#       ASSETS:Personal:BitBrokerB            15 BTC @ 0.2 USD
#       ASSETS:Personal:Bankwest:Cheque      -3.00 USD
#
#     2010-01-13 "I bought 18 BTC at a price of $0.30 USD/BTC"
#       ASSETS:Personal:BitBrokerC            18 BTC @ 0.3 USD
#       ASSETS:Personal:Bankwest:Cheque      -5.40 USD
#
#     # asset transfer to cold storage
#     2010-11-13 "I transferred BTC to cold storage"
#       # 0 BTC was expended, 0 realized capital gains / losses
#       ASSETS:Personal:ColdStorage:Bread     24 BTC @ 0.3 USD
#       ASSETS:Personal:ColdStorage:Paper     24 BTC @ 0.3 USD
#       ASSETS:Personal:BitBrokerA           -15 BTC @ 0.3 USD
#       ASSETS:Personal:BitBrokerB           -15 BTC @ 0.3 USD
#       ASSETS:Personal:BitBrokerC           -18 BTC @ 0.3 USD
#
#     # asset sale in transaction journal entry
#     # this transaction journal EntryID == $tax-id
#     2012-10-26 "I sold 48 BTC at a price of $10.00 USD/BTC"
#       ASSETS:Personal:Bankwest:Cheque       480 USD
#       ASSETS:Personal:ColdStorage:Bread    -24 BTC @ 10 USD
#       ASSETS:Personal:ColdStorage:Paper    -24 BTC @ 10 USD
#
#     --------------------------------------------------------------
#
#     # nightscape's internal translation of asset sale (FIFO/LIFO)
#     2012-10-26 "I sold 48 BTC at a price of $10.00 USD/BTC"
#       ASSETS:Personal:Bankwest:Cheque       480 USD
#       INCOME:Personal:NSAutoCapitalGains    148.50 USD # 0.1 lot
#       INCOME:Personal:NSAutoCapitalGains    147.00 USD # 0.2 lot
#       INCOME:Personal:NSAutoCapitalGains    174.60 USD # 0.3 lot
#       ASSETS:Personal:ColdStorage:Bread    -15 BTC @ 0.1 USD
#       ASSETS:Personal:ColdStorage:Bread    -9 BTC @ 0.2 USD
#       ASSETS:Personal:ColdStorage:Paper    -6 BTC @ 0.2 USD
#       ASSETS:Personal:ColdStorage:Paper    -18 BTC @ 0.3 USD
#       # (sale) ASSETS += 470.10 USD
#       # (gain) INCOME += 470.10 USD
#
#     assert(ASSETS + EXPENSES == INCOME + LIABILITIES + EQUITY)
#
#     # nightscape's internal translation of asset sale (AVCO*)
#     2012-10-26 "I sold 48 BTC at a price of $10.00 USD/BTC"
#       ASSETS:Personal:Bankwest:Cheque       480 USD
#       INCOME:Personal:NSAutoCapitalGains    470.10 USD
#       ASSETS:Personal:ColdStorage:Bread    -24 BTC @ 0.20625 USD
#       ASSETS:Personal:ColdStorage:Paper    -24 BTC @ 0.20625 USD
#       # (sale*) ASSETS += 470.10 USD
#       # (gain*) INCOME += 470.10 USD
#
#     assert(ASSETS + EXPENSES == INCOME + LIABILITIES + EQUITY)
#
# * under AVCO, average cost at expenditure is used in place of
#   acquisition prices {0.1 USD, 0.2 USD, 0.3 USD}:
#
#    avco = ((0.1 * 15) + (0.2 * 15) + (0.3 * 18)) / (15 + 15 + 18)
#         = (1.5 + 3 + 5.4) / 48
#         = 9.9 / 48
#         = 0.20625
#
#    sale = 480 - (48 * 0.20625)
#         = 480 - 9.9
#         = 470.1
#
#    gain = (10 - 0.20625) * 48
#         = 9.79375 * 48
#         = 470.1
#

# vim: ft=perl6
