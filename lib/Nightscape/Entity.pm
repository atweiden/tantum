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
    Nightscape::Entity::COA::Acct :%acct!,
    Nightscape::Entity::Holding :%holdings = %!holdings,
    Nightscape::Entity::Wallet :%wallet = %!wallet
) returns Hash[Nightscape::Entity::Wallet,Silo]
{
    # make copy of %wallet for incising realized capital gains / losses
    my Nightscape::Entity::Wallet %wllt{Silo};
    for %wallet.kv -> $silo, $wallet
    {
        %wllt{::($silo)} = Nightscape::Entity::Wallet.new(
            :balance($wallet.balance.clone),
            :subwallet($wallet.subwallet.clone)
        );
    }

    # for each asset code in holdings
    for %holdings.keys -> $asset_code
    {
        # this asset code in holdings
        my Nightscape::Entity::Holding $holdings = %holdings{$asset_code};

        # fetch costing method for asset code
        my Costing $costing = $GLOBAL::CONF.resolve_costing(
            :$asset_code,
            :entity_name($!entity_name)
        );

        # for each entry UUID resulting in realized capital gains / losses
        for $holdings.taxes.keys -> $tax_uuid
        {
            # fetch all realized capital gains / losses from this entry UUID
            my Nightscape::Entity::Holding::Taxes @taxes =
                $holdings.taxes{$tax_uuid}.list;

            # sum realized capital gains / losses
            my Quantity $capital_gains = [+] @taxes».capital_gains;
            my Quantity $capital_losses = [+] @taxes».capital_losses;

            # take difference of realized capital gains and losses
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
                # in theory not possible for gains_less_losses ~~ 0 since
                # realized capital gains and realized capital losses of
                # a certain asset, on a per entry basis, can't have both
                # capital losses and capital gains as there can only be
                # one exchange rate per asset per entry; and we are only
                # pursuing entries that resulted in >0 realized capital
                # gains or >0 realized capital losses
            }

            # fetch targets for incising realized capital gains / losses
            my Nightscape::Entity::COA::Acct %targets{AcctName} = %acct.grep({
                # only find targets in Silo ASSETS
                .value.path[0] ~~ "ASSETS"
            }).grep({
                # only find targets with matching asset code and entry UUID
                .value.entry_uuids_by_asset{$asset_code}.grep($tax_uuid)
            });

            # fetch acquisition price / avco for asset code
            my Quantity $xe_asset_quantity =
                $holdings.resolve_holding_basis_price(
                    :$costing,
                    :uuid($tax_uuid)
                );

            # for each target Silo ASSETS wallet
            for %targets.kv -> $acct_name, $acct
            {
                # update Changeset exchange rate to allow room for
                # balancing realized capital gains / losses
                &in_wallet(%wllt{::($acct.path[0])}, $acct.path[1..*]).mod_xeaq(
                    :$asset_code,
                    :entry_uuid($tax_uuid),
                    :$xe_asset_quantity
                );

                # entity base currency
                # - all basis prices are in terms of entity's base currency
                # - all capital gains are be in terms of entity's base currency
                my AssetCode $entity_base_currency =
                    $GLOBAL::CONF.resolve_base_currency($!entity_name);

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

                # verify the fundamental accounting equation remains balanced
            }
        }
    }

    %wllt;
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
        $!entity_name
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
            :$!entity_name
        );

        # prepare cost basis data
        my Date $date = $entry.header.date;
        my Price $price = @p[0].amount.exchange_rate.asset_quantity;

        # build mod_holdings
        %mod_holdings{$aux_asset_code} =
            Nightscape::Entity::TXN::ModHolding.new(
                :asset_code($aux_asset_code),
                :$asset_flow,
                :$costing,
                :$date,
                :$price,
                :$quantity
            );
    }

    # build transaction
    Nightscape::Entity::TXN.new(:$uuid, :%mod_holdings, :@mod_wallet);
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

method get_eqbal(
    Nightscape::Entity::Wallet :%wallet = $!coa.wllt
) returns Hash[Rat,Silo]
{
    my AssetCode $entity_base_currency =
        $GLOBAL::CONF.resolve_base_currency($!entity_name);

    my Rat %balance{Silo};

    for self.ls_assets_handled -> $asset_code
    {
        for %wallet.keys -> $silo
        {
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
    # is $!coa missing?
    unless $!coa
    {
        # error: COA missing
        die "Sorry, COA missing; needed for Entity.ls_assets_handled";
    }

    my AssetCode @assets_handled;

    for $!coa.acct.kv -> $acct_name, $acct
    {
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
    # use %!acct to find target list with wallet path
    my Nightscape::Entity::Wallet %wllt{Silo} = self.acct2wllt(:%acct);

    # force instantiate new coa?
    if $force
    {
        # instantiate coa
        $!coa = Nightscape::Entity::COA.new(:%acct, :%wllt);
    }
    # does coa exist?
    elsif $!coa
    {
        # error: coa exists, pass arg :force to overwrite
        die "Sorry, cannot create COA self.coa: self.coa exists";
    }
    else
    {
        # instantiate coa
        $!coa = Nightscape::Entity::COA.new(:%acct, :%wllt);
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
    Quantity :$quantity!
)
{
    # acquisition?
    if $asset_flow ~~ ACQUIRE
    {
        # instantiate holding if needed
        unless %!holdings{$asset_code}
        {
            %!holdings{$asset_code} = Nightscape::Entity::Holding.new(
                :$asset_code
            );
        }

        # acquire asset
        %!holdings{$asset_code}.acquire(:$uuid, :$date, :$price, :$quantity);
    }
    # expenditure?
    elsif $asset_flow ~~ EXPEND
    {
        # if holding does not exist, exit with an error
        unless %!holdings{$asset_code}
        {
            die qq:to/EOF/;
            Sorry, no holding exists of asset code 「$asset_code」.
            EOF
        }

        # check for sufficient unit quantity of asset in holdings
        my Quantity $quantity_held = %!holdings{$asset_code}.get_total_quantity;
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
        %!holdings{$asset_code}.expend(:$uuid, :$costing, :$price, :$quantity);
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
    unless %!wallet{$silo}
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
            my Quantity $quantity = $mod_holding.quantity;

            self!mod_holdings(
                :$uuid,
                :$asset_code,
                :$asset_flow,
                :$costing,
                :$date,
                :$price,
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
    Nightscape::Entity::Wallet :%wallet = %!wallet,
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
        loop (my Int $i = 0; $i < @tree.elems; $i++)
        {
            @tree[$i].unshift(~$silo);
        }

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
        my Nightscape::Entity::Wallet $wallet = %!wallet{::(@path[0])};

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

# vim: ft=perl6
