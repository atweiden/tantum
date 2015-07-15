use v6;
use Nightscape::Entity::COA;
use Nightscape::Entity::Holding;
use Nightscape::Entity::TXN;
use Nightscape::Entity::Wallet;
use Nightscape::Entry;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity;

# entity name
has VarName $.entity_name;

# chart of accounts (acct, eq, wllt)
has Nightscape::Entity::COA $.coa;

# holdings with cost basis, indexed by asset code
has Nightscape::Entity::Holding %.holdings{AssetCode};

# transactions queue
has Nightscape::Entity::TXN @.transactions;

# wallets indexed by silo
has Nightscape::Entity::Wallet %.wallet{Silo};

# given holdings + wallet, return wllt including capital gains / losses
method acct2wllt(
    Nightscape::Entity::COA::Acct :%acct! is readonly,
    Nightscape::Entity::Holding :%holdings is readonly = %.holdings,
    Nightscape::Entity::Wallet :%wallet is readonly = %.wallet
) returns Hash[Nightscape::Entity::Wallet,Silo]
{
    # get entity base currency for cross-checking acquisition price asset codes
    my AssetCode $entity_base_currency = $GLOBAL::CONF.resolve_base_currency(
        $.entity_name
    );

    # make copy of %wallet for incising realized capital gains / losses
    my Nightscape::Entity::Wallet %wllt{Silo};
    for %wallet.kv -> $silo, $wallet
    {
        %wllt{::($silo)} = $wallet.clone;
    }

    # for each asset code in holdings
    for %holdings.kv -> $asset_code, $holdings
    {
        # fetch costing method for asset code
        my Costing $costing = $GLOBAL::CONF.resolve_costing(
            :$asset_code,
            :$.entity_name
        );

        # for each entry UUID resulting in realized capital gains / losses for
        # this asset code
        for $holdings.taxes.kv -> $tax_uuid, @taxes
        {
            # ensure all original quantities expended are quoted in the
            # asset code $asset_code
            for @taxes
            {
                # was incorrect asset code expended?
                unless $^a.quantity_expended_asset_code ~~ $asset_code
                {
                    # error: improper asset code expended
                    die "Sorry, improper asset code expended in tax event";
                }

                # did asset code used for acquisition price differ from
                # entity's base currency?
                unless $^a.acquisition_price_asset_code ~~ $entity_base_currency
                {
                    # error: acquisition price asset code differs from
                    # entity base currency
                    die "Sorry, asset code for acquisition price differs
                         from entity base currency";
                }
            }

            # fetch all accts containing this asset code with changesets created
            # from entry UUID $tax_uuid
            # - associated realized capital gains / losses must have resulted
            #   from the assorted changesets in these wallets
            # - we're grepping for wallet paths containing Wallet.balance
            #   adjustment events only of asset code $asset_code, and caused only
            #   by entry UUID $tax_uuid leading to realized capital gains or
            #   realized capital losses
            #   - the changesets are not being pointed to, just the wallets
            #     containing those changesets
            my Nightscape::Entity::COA::Acct %acct_targets{AcctName} =
                %acct.grep({
                    # only find targets in Silo ASSETS
                    .value.path[0] ~~ "ASSETS"
                }).grep({
                    # only find targets with matching asset code and entry UUID
                    .value.entry_uuids_by_asset{$asset_code}.grep(
                        $tax_uuid
                    )
                });

            # total quantity debited in targets, separately and in total
            #
            #     TotalQuantityDebited => %(
            #         TargetAcctName => %(
            #             TargetAcctDebitQuantity => %(
            #                 PostingUUID => PostingUUIDBalanceDelta,
            #                 PostingUUID => PostingUUIDBalanceDelta,
            #                 PostingUUID => PostingUUIDBalanceDelta
            #             )
            #         ),
            #         TargetAcctName => %(
            #             TargetAcctDebitQuantity => %(
            #                 PostingUUID => PostingUUIDBalanceDelta,
            #                 PostingUUID => PostingUUIDBalanceDelta,
            #                 PostingUUID => PostingUUIDBalanceDelta
            #             )
            #         )
            #     )
            #
            # where:
            #
            # - TotalQuantityDebited is sum of all TargetAcctDebitQuantity
            # - TargetAcctName is COA::Acct.name ("ASSETS:Personal:Bankwest")
            # - TargetAcctDebitQuantity is sum of all PostingUUIDBalanceDelta
            # - PostingUUID is UUID of posting in Entry UUID causing
            #   this round of realized capital gains / losses, wrt asset
            #   code $asset_code
            #   - get_total_quantity_debited calls
            #         Wallet.ls_changesets(
            #             asset_code => $asset_code,
            #             entry_uuid => $tax_uuid
            #         );
            # - PostingUUIDBalanceDelta is Changeset.balance_delta
            my Hash[Hash[Hash[Rat,UUID],Quantity],AcctName]
                %total_quantity_debited{Quantity} = get_total_quantity_debited(
                        :%acct_targets,
                        :$asset_code,
                        :entry_uuid($tax_uuid),
                        :%wallet
                    );
            my Quantity $total_quantity_debited =
                %total_quantity_debited.keys[0];

            # total quantity expended, separately and in total
            my Hash[Quantity,Quantity] %total_quantity_expended{Quantity} =
                get_total_quantity_expended(:$costing, :@taxes);
            my Quantity $total_quantity_expended =
                %total_quantity_expended.keys[0];

            # verify that the sum total quantity being debited from
            # ASSETS wallets == the sum total quantity expended according
            # to Taxes{$tax_uuid}
            #
            # was the total quantity debited of asset code $asset_code in target
            # ASSETS wallets different from the total quantity expended
            # according to Taxes instances generated by entry UUID $tax_uuid?
            #
            # they should always be equivalent
            unless $total_quantity_debited == $total_quantity_expended
            {
                # error: total quantity debited mismatch
                die "Sorry, encountered total quantity debited mismatch";
                # this suggests original Holding.EXPEND call calculation
                # of INCs - DECs contains a bug not caught in testing, or
                # that the above %acct_targets were grepped for using
                # flawed terms, or that Entity.get_total_quantity_debited
                # call to Wallet.ls_changesets produced unexpected results
            }

            # fetch instructions for incising realized capital gains / losses
            # NEW/MOD | AcctName | QuantityToDebit | XE
            my Array[Instruction] %instructions{UUID} = gen_instructions(
                :%total_quantity_debited,
                :%total_quantity_expended
            );

            # apply instructions to balance out NSAutoCapitalGains later
            for %instructions.kv -> $posting_uuid, @instructions
            {
                for @instructions -> $instruction
                {
                    # get wallet path by splitting AcctName on ':'
                    my VarName @path = $instruction<acct_name>.split(
                        ':'
                    );

                    # make new changeset or modify existing, by instruction
                    &in_wallet(%wllt{::(@path[0])}, @path[1..*]).mkchangeset(
                        :$asset_code,
                        :xe_asset_code($entity_base_currency),
                        :entry_uuid($tax_uuid),
                        :$posting_uuid,
                        :$instruction
                    );
                }
            }

            # incise silo INCOME with realized capital gains / losses
            for @taxes -> $tax_event
            {
                # take difference of realized capital gains and losses
                my Quantity $capital_gains = $tax_event.capital_gains;
                my Quantity $capital_losses = $tax_event.capital_losses;
                my Rat $gains_less_losses = $capital_gains - $capital_losses;

                # determine whether gain (INC) or loss (DEC)
                my DecInc $decinc;
                if $gains_less_losses > 0
                {
                    $decinc = INC;
                }
                elsif $gains_less_losses < 0
                {
                    $decinc = DEC;
                }
                else
                {
                    # impossible for gains_less_losses == 0 since
                    # realized capital gains and realized capital losses
                    # of a certain asset, on a per entry basis, can't
                    # have both capital losses and capital gains as there
                    # can only be one exchange rate per asset per entry;
                    # and we are only pursuing entries that resulted in >0
                    # realized capital gains or >0 realized capital losses:
                    #
                    # - an expenditure had to have happened to instantiate
                    #   the Taxes class, creating those capital gains or
                    #   losses with the associated UUID (the 'taxes.keys')
                    # - if (expend price - basis price) * quantity expended > 0,
                    #   only then will a Taxes class be instantiated and
                    #   realized capital gains recorded
                    # - if (expend price - basis price) * quantity expended < 0,
                    #   only then will a Taxes class be instantiated and
                    #   realized capital losses recorded
                    # - under no other conditions would the key $tax_uuid exist
                }

                # purposefully empty vars
                my UUID $posting_uuid;
                my AssetCode $xeac;
                my Quantity $xeaq;

                # enter realized capital capital gains / losses in Silo INCOME
                &in_wallet(%wllt{INCOME}, "NSAutoCapitalGains").mkchangeset(
                    :entry_uuid($tax_uuid),
                    :$posting_uuid,
                    :asset_code($entity_base_currency),
                    :$decinc,
                    :quantity($gains_less_losses.abs),
                    :xe_asset_code($xeac),
                    :xe_asset_quantity($xeaq)
                );
            }
        }
    }

    %wllt;
}

# return instructions for incising realized capital gains / losses
# indexed by causal posting_uuid (NEW/MOD | AcctName | QuantityToDebit | XE)
sub gen_instructions(
    Hash[Hash[Hash[Rat,UUID],Quantity],AcctName] :%total_quantity_debited!,
    Hash[Quantity,Quantity] :%total_quantity_expended!
) returns Hash[Array[Instruction],UUID]
{
    # bucket with fill progress, incl. fills per acquisition price
    class Bucket
    {
        # containing acct (ownership, lookup path)
        has AcctName $.acct_name;

        # bucket max capacity
        has Quantity $.capacity = 0.0;

        # running total filled
        has Quantity $.filled = 0.0;

        # capacity less filled
        has Quantity $.open = $!capacity - $!filled;

        # causal posting UUID
        has UUID $.posting_uuid;

        # subfills indexed by acquisition price
        has Quantity %.subfills{Quantity};

        # add subfill to %.subfills at acquisition price (xe_asset_quantity)
        method mksubfill(
            Quantity :$acquisition_price!,    # price at acquisition (or avco)
            Quantity :$subfill!               # amount to fill at price
        )
        {
            # ensure bucket has capacity open for this subfill
            self!update_open;
            unless $subfill <= $.open
            {
                die "Sorry, cannot mksubfill, not enough capacity remaining";
            }
            %!subfills{$acquisition_price} = $subfill;
            self!update_filled;
            self!update_open;
        }

        # calculate bucket capacity less filled
        method !update_open()
        {
            $!open = $.capacity - $.filled;
        }

        # update $.filled, gets called after every subfill
        method !update_filled()
        {
            my Quantity $filled = 0.0;
            $filled += [+] %.subfills.values;
            $!filled = $filled;
        }
    }

    # make buckets containing amounts needing to be filled in Entity.wallet,
    # indexed by posting UUID, %(PostingUUID => Bucket)
    my Bucket %buckets{UUID};

    # (from data structure of %total_quantity_debited)
    # total quantity debited in targets, separately and in total
    #
    #     TotalQuantityDebited => %(
    #         TargetAcctName => %(
    #             TargetAcctDebitQuantity => %(
    #                 PostingUUID => PostingUUIDBalanceDelta,
    #                 PostingUUID => PostingUUIDBalanceDelta,
    #                 PostingUUID => PostingUUIDBalanceDelta
    #             )
    #         ),
    #         TargetAcctName => %(
    #             TargetAcctDebitQuantity => %(
    #                 PostingUUID => PostingUUIDBalanceDelta,
    #                 PostingUUID => PostingUUIDBalanceDelta,
    #                 PostingUUID => PostingUUIDBalanceDelta
    #             )
    #         )
    #     )
    #
    for %total_quantity_debited.values.list[0].hash.kv ->
        $target_acct_name, %target_acct_debit_quantity
    {
        # for each posting UUID
        for %target_acct_debit_quantity.kv ->
            $target_acct_debit_quantity, %balance_delta_by_posting_uuid
        {
            # instantiate one bucket per posting UUID, only for those postings
            # with negative balance_delta
            #
            # we subdivide only these postings with asset outflows when incising
            # realized capital gains / losses

            # for all %(posting UUID => balance_delta) pairs with
            # Changeset.balance_delta less than zero
            my LessThanZero %bdbpu{UUID} = %balance_delta_by_posting_uuid.grep({
                .value < 0
            });
            for %bdbpu.kv -> $posting_uuid, $balance_delta
            {
                #
                # instantiate bucket, indexed by posting UUID with:
                #
                # - capacity (of the amount expended in the acct per the Entry)
                #   - INCs less DECs to the asset in the original Entry
                #   - this is what the method Entity.get_total_quantity_debited
                #     does when it sums the balance delta of all changesets
                #     particular to an Entry UUID's handling of an asset, one
                #     with realized capital gains / losses
                # - posting UUID
                #   - posting UUID with a Changeset.balance_delta less than
                #     zero
                #     - if the summed balance_deltas are negative for an asset
                #       in a particular entry, at least one of the negative
                #       C<Entry::Posting>s had to be in part responsible for a
                #       holding basis lot expenditure
                #   - suitable for subdividing the balance delta into expended
                #     holding basis lots with differing XE if necessary
                #   - since the changesets are summed, it may not matter whether
                #     we subdivide a positive or a negative
                #     Changeset.balance_delta as the net result of summing
                #     either one should be equivalent
                #   - it's impossible to run out of buckets for an Entry's
                #     expenditures, because net outflows (expenditures) of an
                #     asset will always be less than or equal to the sum of the
                #     Entry's negative-only C<Changeset.balance_delta>s
                #     - paying the Bitcoin miners' fee during an asset transfer
                #       would be an example of an expenditure sized much less
                #       than the sum of the Entry's negative-only balance_deltas
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
                #     # sum of Entry's C<Changeset.balance_delta>s affecting
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
                #     # sum of negative-only C<Changeset.balance_delta>s:
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
                my Quantity $capacity = -$balance_delta; # * -1 since value < 0
                %buckets{$posting_uuid} = Bucket.new(
                    :acct_name($target_acct_name),
                    :$capacity,
                    :$posting_uuid
                );
            }
        }
    }

    # for every subtotal quantity needing a bucket to call home
    # (at acquisition price), put each $subtotal_quantity_expended into
    # bucket until/unless full, then fill next bucket
    for %total_quantity_expended.values.list[0].hash.kv ->
        $acquisition_price, $subtotal_quantity_expended
    {
        # store remaining subtotal still needing to be disbursed to buckets
        my Quantity $remaining = $subtotal_quantity_expended;

        # does any portion of this subtotal still need to be disbursed?
        while $remaining > 0
        {
            # then disburse the remaining amount to buckets
            # - amounts are assigned to each bucket/acct lexically, but
            #   for FIFO/LIFO/AVCO it is arbitrary which wallet spends
            #   which holdings at each price point expended

            # for each pair %(PostingUUID => Bucket)
            for %buckets.kv -> $posting_uuid, $bucket
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
                        :$acquisition_price,
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
                        :$acquisition_price,
                        :subfill($remaining)
                    );

                    # ensure $remaining less $remaining is 0
                    $remaining -= $remaining;

                    # break from this original subtotal quantity lot needing
                    # a bucket to call home at acquisition price, no more
                    # of it is remaining
                    last;
                }
            }
        }
    }

    # store lists of instructions indexed by causal posting UUID indexed
    # by acct name
    my Array[Instruction] %instructions{UUID};

    # convert %buckets to instructions
    for %buckets.kv -> $posting_uuid, $bucket
    {
        # store list of instructions generated from buckets
        my Instruction @instructions;

        # acct name
        my AcctName $acct_name = $bucket.acct_name;

        # does bucket have capacity remaining?
        if $bucket.open
        {
            # set orig bucket = open size
            {
                my NewMod $newmod = MOD;
                my Quantity $quantity_to_debit = $bucket.open;
                my Quantity $xe = Nil;
                my Instruction $instruction = {
                    :$acct_name,
                    :$newmod,
                    :$quantity_to_debit,
                    :$xe
                };
                push @instructions, $instruction;
            }

            # create one more bucket foreach $bucket.subfills.keys[0..*]
            for $bucket.subfills.kv -> $acquisition_price, $quantity_to_debit
            {
                my NewMod $newmod = NEW;
                my Quantity $xe = $acquisition_price;
                my Instruction $instruction = {
                    :$acct_name,
                    :$newmod,
                    :$quantity_to_debit,
                    :$xe
                };
                push @instructions, $instruction;
            }
        }
        else
        {
            # set orig bucket = $bucket.subfills.keys[0]
            {
                my NewMod $newmod = MOD;
                my Quantity $quantity_to_debit = $bucket.subfills.values[0];
                my Quantity $xe = $bucket.subfills.keys[0];
                my Instruction $instruction = {
                    :$acct_name,
                    :$newmod,
                    :$quantity_to_debit,
                    :$xe
                };
                push @instructions, $instruction;
            }

            # create one more bucket foreach $bucket.subfills.keys[1..*]
            loop (my Int $i = 1; $i < $bucket.subfills.elems; $i++)
            {
                my NewMod $newmod = NEW;
                my Quantity $quantity_to_debit = $bucket.subfills.values[$i];
                my Quantity $xe = $bucket.subfills.keys[$i];
                my Instruction $instruction = {
                    :$acct_name,
                    :$newmod,
                    :$quantity_to_debit,
                    :$xe
                };
                push @instructions, $instruction;
            }
        }

        push %instructions{$posting_uuid}, @instructions;
    }

    %instructions;
}

# given entry, return instantiated transaction
method gen_txn(
    Nightscape::Entry :$entry!
) returns Nightscape::Entity::TXN
{
    # verify entry is balanced or exit with an error
    unless $entry.is_balanced
    {
        die qq:to/EOF/
        Sorry, cannot gen_txn: entry not balanced

        「$entry」
        EOF
    }

    # source entry uuid
    my UUID $uuid = $entry.header.uuid;

    # transaction data storage
    my Nightscape::Entity::TXN::ModHolding %mod_holdings{AssetCode};
    my Nightscape::Entity::TXN::ModWallet @mod_wallet;

    # build mod_wallet for dec/inc applicable wallet balance
    for $entry.postings -> $posting
    {
        # from Nightscape::Entry::Posting
        my UUID $posting_uuid = $posting.posting_uuid;
        my Nightscape::Entry::Posting::Account $account = $posting.account;
        my Nightscape::Entry::Posting::Amount $amount = $posting.amount;
        my DecInc $decinc = $posting.decinc;

        # from Nightscape::Entry::Posting::Account
        my Silo $silo = $account.silo;
        my VarName @subwallet = $account.subaccount;

        # from Nightscape::Entry::Posting::Amount
        my AssetCode $asset_code = $amount.asset_code;
        my Quantity $quantity = $amount.asset_quantity;

        # from Nightscape::Entry::Posting::Amount::XE
        my AssetCode $xe_asset_code;
        $xe_asset_code = try {$amount.exchange_rate.asset_code};
        my Quantity $xe_asset_quantity;
        $xe_asset_quantity = try {$amount.exchange_rate.asset_quantity};

        # build mod_wallet
        push @mod_wallet, Nightscape::Entity::TXN::ModWallet.new(
            :entry_uuid($uuid),
            :$posting_uuid,
            :$asset_code,
            :$decinc,
            :$quantity,
            :$silo,
            :@subwallet,
            :$xe_asset_code,
            :$xe_asset_quantity
        );
    }

    # build mod_holdings for acquire/expend the applicable holdings

    # find entry postings affecting silo ASSETS
    my Silo $silo = ASSETS;
    my Nightscape::Entry::Posting @postings = $entry.postings;
    my Nightscape::Entry::Posting @postings_assets_silo =
        Nightscape::Entry.ls_postings(:@postings, :$silo);

    # find entry postings affecting silo ASSETS, entity base currency only
    my AssetCode $entity_base_currency = $GLOBAL::CONF.resolve_base_currency(
        $.entity_name
    );
    my Regex $asset_code = /$entity_base_currency/;
    my Nightscape::Entry::Posting @postings_assets_silo_base_currency =
        Nightscape::Entry.ls_postings(:@postings, :$asset_code, :$silo);

    # filter out base currency postings
    my Set $postings_remainder{Nightscape::Entry::Posting} =
        @postings_assets_silo (-) @postings_assets_silo_base_currency;
    my Nightscape::Entry::Posting @postings_remainder =
        $postings_remainder.list;

    # find unique aux asset codes
    my VarName @aux_asset_codes = Nightscape::Entry.ls_asset_codes(
        :postings(@postings_remainder)
    );

    # calculate difference between INCs and DECs for each aux asset code
    for @aux_asset_codes -> $aux_asset_code
    {
        # filter for postings only of this asset code
        my Nightscape::Entry::Posting @p = Nightscape::Entry.ls_postings(
            :postings(@postings_remainder),
            :asset_code(/$aux_asset_code/)
        );

        # sum INCs
        my Nightscape::Entry::Posting @p_inc = @p.grep({ .decinc ~~ INC });
        my Rat $incs = Rat([+] (.amount.asset_quantity for @p_inc));

        # sum DECs
        my Nightscape::Entry::Posting @p_dec = @p.grep({ .decinc ~~ DEC });
        my Rat $decs = Rat([+] (.amount.asset_quantity for @p_dec));

        # INCs - DECs
        my Rat $d = $incs - $decs;

        # asset flow: acquire / expend
        my AssetFlow $asset_flow = Nightscape::Types.mkasset_flow($d);

        # asset quantity
        my Quantity $quantity = $d.abs;

        # asset costing method
        my Costing $costing = $GLOBAL::CONF.resolve_costing(
            :asset_code($aux_asset_code),
            :$.entity_name
        );

        # prepare cost basis data
        my Date $date = $entry.header.date;
        my Price $price = @p[0].amount.exchange_rate.asset_quantity;
        my AssetCode $acquisition_price_asset_code =
            @p[0].amount.exchange_rate.asset_code;

        # build mod_holdings
        %mod_holdings{$aux_asset_code} =
            Nightscape::Entity::TXN::ModHolding.new(
                :asset_code($aux_asset_code),
                :$asset_flow,
                :$costing,
                :$date,
                :$price,
                :$acquisition_price_asset_code,
                :$quantity
            );
    }

    # build transaction
    Nightscape::Entity::TXN.new(:$uuid, :%mod_holdings, :@mod_wallet);
}

# get quantity debited in targets, separately and in total
sub get_total_quantity_debited(
    Nightscape::Entity::COA::Acct :%acct_targets!,
    AssetCode :$asset_code!,
    UUID :$entry_uuid!,
    Nightscape::Entity::Wallet :%wallet!
) returns Hash[Hash[Hash[Hash[Rat,UUID],Quantity],AcctName],Quantity]
{
    # store total quantity debited
    my Quantity $total_quantity_debited;

    # store Changeset.balance_delta indexed by posting UUID, indexed by subtotal
    # quantity debited in the acct (the sum of balance deltas one per posting),
    # indexed by acct name:
    #
    #     TargetAcctName => %(
    #         TargetAcctDebitQuantity => %(
    #             PostingUUID => PostingUUIDBalanceDelta,
    #             PostingUUID => PostingUUIDBalanceDelta,
    #             PostingUUID => PostingUUIDBalanceDelta
    #         )
    #     ),
    #     TargetAcctName => %(
    #         TargetAcctDebitQuantity => %(
    #             PostingUUID => PostingUUIDBalanceDelta,
    #             PostingUUID => PostingUUIDBalanceDelta,
    #             PostingUUID => PostingUUIDBalanceDelta
    #         )
    #     )
    #
    #  -------
    #
    #  $total_quantity_debited = [+] (.TargetAcctDebitQuantity for TargetAcctName)
    #
    my Hash[Hash[Rat,UUID],Quantity] %total_debits_per_acct{AcctName};

    # for each target acct
    for %acct_targets.kv -> $acct_name, $acct
    {
        # get all those changesets in acct affecting only asset code $asset_code,
        # and sharing entry's UUID $entry_uuid
        my Nightscape::Entity::Wallet::Changeset @changesets =
            &in_wallet(%wallet{::($acct.path[0])}, $acct.path[1..*]).ls_changesets(
                :$asset_code,
                :$entry_uuid
            );

        # stores each changeset's debit quantity, indexed by posting UUID
        #
        #     %(
        #         PostingUUID => PostingUUIDBalanceDelta,
        #         PostingUUID => PostingUUIDBalanceDelta,
        #         PostingUUID => PostingUUIDBalanceDelta
        #     )
        #
        my Rat %balance_delta_by_posting_uuid{UUID};

        # for all those changesets in acct affecting only asset code $asset_code,
        # and sharing entry's UUID $entry_uuid
        for @changesets -> $changeset
        {
            # causal posting's uuid, for precise changeset lookups
            my UUID $posting_uuid = $changeset.posting_uuid;

            # causal posting's balance adjustment, for summing
            my Rat $posting_uuid_balance_delta = $changeset.balance_delta;

            %balance_delta_by_posting_uuid{$posting_uuid} =
                $posting_uuid_balance_delta;
        }

        # sum posting balance deltas, should be less than zero, representing net
        # expenditure/outflow of asset from ASSETS wallet
        my LessThanZero $target_acct_balance_delta_sum =
            [+] %balance_delta_by_posting_uuid.values;

        # since we're sure the delta sum is less than zero, take absolute value
        # to get target acct debit quantity
        my Quantity $target_acct_debit_quantity =
            $target_acct_balance_delta_sum.abs;

        # the intuitive version doesn't work
        #     %total_debits_per_acct{$acct.name}{$target_acct_debit_quantity} =
        #         $%balance_delta_by_posting_uuid;
        #
        # helper:
        my Hash[Rat,UUID] %target_acct_debit_quantity{Quantity} =
            $target_acct_debit_quantity => $%balance_delta_by_posting_uuid;
        %total_debits_per_acct{$acct_name} = $%target_acct_debit_quantity;

        # add subtotal balance delta to total quantity debited
        $total_quantity_debited += $target_acct_debit_quantity;
    }

    # TotalQuantityDebited => %(
    #     TargetAcctName => %(
    #         TargetAcctDebitQuantity => %(
    #             PostingUUID => PostingUUIDBalanceDelta,
    #             PostingUUID => PostingUUIDBalanceDelta,
    #             PostingUUID => PostingUUIDBalanceDelta
    #         )
    #     ),
    #     TargetAcctName => %(
    #         TargetAcctDebitQuantity => %(
    #             PostingUUID => PostingUUIDBalanceDelta,
    #             PostingUUID => PostingUUIDBalanceDelta,
    #             PostingUUID => PostingUUIDBalanceDelta
    #         )
    #     )
    # )
    #
    # TotalQuantityDebited ----------------------------------------------------+
    # TargetAcctName ------------------------+                                 |
    # TargetAcctDebitQuantity ------+        |                                 |
    # PostingUUID -----------+      |        |                                 |
    #PostingUUIDBalanceDelta |      |        |                                 |
    #                  |     |      |        |                                 |
    #                  |     |      |        |                                 |
    my Hash[Hash[Hash[Rat,UUID],Quantity],AcctName] %total_quantity_debited{Quantity} =
            $total_quantity_debited => %total_debits_per_acct;
}

# get quantity expended of a holding indexed by acquisition price,
# indexed by total quantity expended
sub get_total_quantity_expended(
    Costing :$costing!,
    Nightscape::Entity::Holding::Taxes :@taxes!
) returns Hash[Hash[Quantity,Quantity],Quantity]
{
    # store total quantity expended
    my Hash[Quantity,Quantity] %total_quantity_expended{Quantity};
    my Quantity $total_quantity_expended;
    my Quantity %per_basis_lot{Quantity};

    for @taxes -> $tax_event
    {
        # get subtotal quantity expended, and add to total
        my Quantity $subtotal_quantity_expended = $tax_event.quantity_expended;
        $total_quantity_expended += $subtotal_quantity_expended;

        # store acquisition price / avco for this tax uuid
        my Quantity $xe_asset_quantity;

        # AVCO costing method?
        if $costing ~~ AVCO
        {
            # retrieve avco at expenditure of holding expended
            $xe_asset_quantity = $tax_event.avco_at_expenditure;
        }
        # FIFO/LIFO costing method?
        elsif $costing ~~ FIFO or $costing ~~ LIFO
        {
            # retrieve acquisition price of holding expended
            $xe_asset_quantity = $tax_event.acquisition_price;
        }

        # record acquisition price => subtotal quantity expended key-value pair
        # in %per_basis_lot
        %per_basis_lot{$xe_asset_quantity} = $subtotal_quantity_expended;
    }

    %total_quantity_expended = $total_quantity_expended => $%per_basis_lot;
}

# given a wallet, and subwallet name list, return scalar container of
# the deepest subwallet
#
# has harmless side effect of creating new and often empty Wallet classes
sub in_wallet(Nightscape::Entity::Wallet $wallet, *@subwallet) is rw
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

# recursively sum balances in terms of entity base currency,
# all wallets in all Silos
method get_eqbal(
    Nightscape::Entity::Wallet :%wallet = $.coa.wllt
) returns Hash[Rat,Silo]
{
    # entity base currency
    my AssetCode $entity_base_currency =
        $GLOBAL::CONF.resolve_base_currency($.entity_name);

    # store total sum Rat balance indexed Silo
    my Rat %balance{Silo};

    # for all assets handled by this entity
    for self.ls_assets_handled -> $asset_code
    {
        # for all wallets in all Silos
        for %wallet.keys -> $silo
        {
            # adjust Silo wallet's running balance (in entity's base currency)
            %balance{::($silo)} += in_wallet(%wallet{::($silo)}).get_balance(
                :$asset_code,
                :base_currency($entity_base_currency),
                :recursive
            );
        }
    }

    %balance;
}

# list all unique asset codes handled by entity
method ls_assets_handled() returns Array[AssetCode]
{
    # is $.coa missing?
    unless $.coa
    {
        # error: COA missing
        die "Sorry, COA missing; needed for Entity.ls_assets_handled";
    }

    # store assets handled by entity
    my AssetCode @assets_handled;

    # for all accts
    for $.coa.acct.kv -> $acct_name, $acct
    {
        # record assets handled in this acct
        push @assets_handled, $acct.assets_handled;
    }

    @assets_handled .= unique;
}

# instantiate entity's chart of accounts
method mkcoa(Bool :$force)
{
    # store accts indexed by acct name
    my Nightscape::Entity::COA::Acct %acct{AcctName} = self.tree2acct;

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

# acquire/expend the applicable holdings
method !mod_holdings(
    UUID :$uuid!,
    AssetCode :$asset_code!,
    AssetFlow :$asset_flow!,
    Costing :$costing!,
    Date :$date!,
    Price :$price!,
    AssetCode :$acquisition_price_asset_code!,
    Quantity :$quantity!
)
{
    # acquisition?
    if $asset_flow ~~ ACQUIRE
    {
        # instantiate holding if needed
        unless %.holdings{$asset_code}
        {
            %!holdings{$asset_code} = Nightscape::Entity::Holding.new(
                :$asset_code
            );
        }

        # acquire asset
        %!holdings{$asset_code}.acquire(
            :$uuid,
            :$date,
            :$price,
            :$acquisition_price_asset_code,
            :$quantity
        );
    }
    # expenditure?
    elsif $asset_flow ~~ EXPEND
    {
        # if holding does not exist, exit with an error
        unless %.holdings{$asset_code}
        {
            die qq:to/EOF/;
            Sorry, no holding exists of asset code 「$asset_code」.
            EOF
        }

        # check for sufficient unit quantity of asset in holdings
        my Quantity $quantity_held = %.holdings{$asset_code}.get_total_quantity;
        unless $quantity_held >= $quantity
        {
            die qq:to/EOF/;
            Sorry, cannot mod_holdings.expend: found insufficient quantity
            of asset 「$asset_code」 in holdings.

            Units needed of $asset_code: 「$quantity」
            Units held of $asset_code: 「$quantity_held」
            EOF
        }

        # expend asset
        %!holdings{$asset_code}.expend(
            :$uuid,
            :$asset_code,
            :$costing,
            :$price,
            :$acquisition_price_asset_code,
            :$quantity
        );
    }
    # stable?
    elsif $asset_flow ~~ STABLE
    {
        # no change, likely an intra-entity asset transfer
    }
}

# dec/inc the applicable wallet balance
method !mod_wallet(
    UUID :$entry_uuid!,
    UUID :$posting_uuid!,
    AssetCode :$asset_code!,
    DecInc :$decinc!,
    Quantity :$quantity!,
    Silo :$silo!,
    AssetCode :$xe_asset_code,
    Quantity :$xe_asset_quantity,
    :@subwallet! # Constraint type check failed for parameter '@subwallet'
)
{
    # ensure $silo wallet exists (potential side effect)
    unless %.wallet{$silo}
    {
        %!wallet{$silo} = Nightscape::Entity::Wallet.new;
    }

    # dec/inc wallet balance (potential side effect from &in_wallet)
    &in_wallet(%!wallet{$silo}, @subwallet).mkchangeset(
        :$entry_uuid,
        :$posting_uuid,
        :$asset_code,
        :$decinc,
        :$quantity,
        :$xe_asset_code,
        :$xe_asset_quantity
    );
}

# execute transaction
method transact(Nightscape::Entity::TXN :$transaction!)
{
    # uuid from causal transaction journal entry
    my UUID $uuid = $transaction.uuid;

    # mod holdings (only needed for entries dealing in aux assets)
    my Nightscape::Entity::TXN::ModHolding %mod_holdings{AssetCode} =
        $transaction.mod_holdings;
    if %mod_holdings
    {
        for %mod_holdings.kv -> $asset_code, $mod_holding
        {
            my AssetFlow $asset_flow = $mod_holding.asset_flow;
            my Costing $costing = $mod_holding.costing;
            my Date $date = $mod_holding.date;
            my Price $price = $mod_holding.price;
            my AssetCode $acquisition_price_asset_code =
                $mod_holding.acquisition_price_asset_code;
            my Quantity $quantity = $mod_holding.quantity;

            self!mod_holdings(
                :$uuid,
                :$asset_code,
                :$asset_flow,
                :$costing,
                :$date,
                :$price,
                :$acquisition_price_asset_code,
                :$quantity
            )
        }
    }

    # mod wallet balances
    my Nightscape::Entity::TXN::ModWallet @mod_wallet = $transaction.mod_wallet;
    for @mod_wallet -> $mod_wallet
    {
        my UUID $posting_uuid = $mod_wallet.posting_uuid;
        my AssetCode $asset_code = $mod_wallet.asset_code;
        my DecInc $decinc = $mod_wallet.decinc;
        my Quantity $quantity = $mod_wallet.quantity;
        my Silo $silo = $mod_wallet.silo;
        my VarName @subwallet = $mod_wallet.subwallet;
        my AssetCode $xe_asset_code;
        $xe_asset_code = try {$mod_wallet.xe_asset_code};
        my Quantity $xe_asset_quantity;
        $xe_asset_quantity = try {$mod_wallet.xe_asset_quantity};

        self!mod_wallet(
            :entry_uuid($uuid),
            :$posting_uuid,
            :$asset_code,
            :$decinc,
            :$quantity,
            :$silo,
            :@subwallet,
            :$xe_asset_code,
            :$xe_asset_quantity
        );
    }
}

# list wallet tree recursively
method tree(
    Nightscape::Entity::Wallet :%wallet = %.wallet,
    Silo :$silo,
    *@subwallet
) returns Array[Array[VarName]]
{
    # store wallet tree
    my Array[VarName] @tree;

    # was $silo arg specified?
    if defined $silo
    {
        # does Silo wallet not exist?
        unless %wallet{::($silo)}
        {
            # instantiate it
            %wallet{::($silo)} = Nightscape::Entity::Wallet.new;
        }

        # fill tree
        @tree = Nightscape::Entity::Wallet.tree(
            &in_wallet(%wallet{$silo}, @subwallet).tree(:hash)
        );

        # prepend Silo to tree branches
        .unshift(~$silo) for @tree;

        # insert root Silo wallet
        {
            my VarName @root_silo_wallet = ~$silo;
            @tree.unshift: $@root_silo_wallet;
        }
    }
    else
    {
        # assume all Silos were requested
        push @tree, self.tree(:%wallet, :silo(::($_)), @subwallet)
            for Silo.enums.keys;
    }

    # return sorted tree
    @tree .= sort;
}

# given wallet tree, generate hash of accts, indexed by acct name
method tree2acct(
    Array[VarName] :@tree = self.tree
) returns Hash[Nightscape::Entity::COA::Acct,AcctName]
{
    # store accts indexed by acct name
    my Nightscape::Entity::COA::Acct %acct{AcctName};

    # for every acct
    for @tree -> @path
    {
        # store acct name
        my AcctName $name = @path.join(':');

        # root Silo wallet
        my Nightscape::Entity::Wallet $wallet = %.wallet{::(@path[0])};

        # store all assets handled
        my AssetCode @assets_handled =
            in_wallet($wallet, @path[1..*]).ls_assets;

        # store entry uuids handled, indexed by asset code
        my Array[UUID] %entry_uuids_by_asset{AssetCode} =
            in_wallet($wallet, @path[1..*]).ls_assets_with_uuids;

        # store posting uuids handled, indexed by asset code
        my Array[UUID] %posting_uuids_by_asset{AssetCode} =
            in_wallet($wallet, @path[1..*]).ls_assets_with_uuids(:posting);

        # store all entry uuids handled
        my UUID @entry_uuids_handled =
            in_wallet($wallet, @path[1..*]).ls_uuids;

        # store all posting uuids handled
        my UUID @posting_uuids_handled =
            in_wallet($wallet, @path[1..*]).ls_uuids(:posting);

        # instantiate acct
        %acct{$name} = Nightscape::Entity::COA::Acct.new(
            :$name,
            :@path,
            :@assets_handled,
            :%entry_uuids_by_asset,
            :@entry_uuids_handled,
            :%posting_uuids_by_asset
            :@posting_uuids_handled
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
#   entry UUID
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
#     # this transaction journal entry's UUID ~~ $tax_uuid
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
