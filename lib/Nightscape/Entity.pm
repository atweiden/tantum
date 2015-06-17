use v6;
use Nightscape::Entity::Holding;
use Nightscape::Entity::Wallet;
use Nightscape::Entry;
use Nightscape::Transaction;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity;

# entity name
has VarName $.entity_name;

# holdings with cost basis, indexed by asset code
has Nightscape::Entity::Holding %.holdings{AssetCode};

# transactions queue
has Nightscape::Transaction @.transactions;

# wallets indexed by silo
has Nightscape::Entity::Wallet %.wallet{Silo};

# given a wallet, and subwallet name list, return scalar container of
# the deepest subwallet
#
# has harmless side effect of creating new and often empty Wallet classes
sub deref(Nightscape::Entity::Wallet $wallet, *@subwallet) is rw
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

# given an entry:
# - verify entry is balanced or exit with an error
#   - side effect of instantiating XE class for exchange rates from config
# - get scalar container of target wallet for dec/inc balance
#   - side effect of instantiating Wallet classes
# - dec/inc the applicable wallet balance
# - acquire/expend the applicable holdings

# given entry, return instantiated transaction
method gen_transaction(
    Nightscape::Entry :$entry!
) returns Nightscape::Transaction
{
    # verify entry is balanced or exit with an error
    unless $entry.is_balanced
    {
        die qq:to/EOF/
        Sorry, cannot gen_transaction: entry not balanced

        「$entry」
        EOF
    }

    # source entry uuid
    my UUID $uuid = $entry.header.uuid;

    # transaction data storage
    my Nightscape::Transaction::ModHolding %mod_holdings{AssetCode};
    my Nightscape::Transaction::ModWallet @mod_wallet;

    # build mod_wallet for dec/inc applicable wallet balance
    for $entry.postings -> $posting
    {
        # from Nightscape::Entry::Posting
        my Nightscape::Entry::Posting::Account $account = $posting.account;
        my Nightscape::Entry::Posting::Amount $amount = $posting.amount;
        my DecInc $decinc = $posting.decinc;

        # from Nightscape::Entry::Posting::Account
        my Silo $silo = $account.silo;
        my VarName @subwallet = $account.subaccount;

        # from Nightscape::Entry::Posting::Amount
        my AssetCode $asset_code = $amount.asset_code;
        my Quantity $quantity = $amount.asset_quantity;

        # build mod_wallet
        push @mod_wallet, Nightscape::Transaction::ModWallet.new(
            :$asset_code,
            :$decinc,
            :$quantity,
            :$silo,
            :@subwallet
        );
    }

    # build mod_holdings for acquire/expend the applicable holdings

    # find entry postings affecting silo ASSETS
    my Silo $silo = ASSETS;
    my Nightscape::Entry::Posting @postings = $entry.postings;
    my Nightscape::Entry::Posting @postings_assets_silo =
        Nightscape::Entry.ls_postings(
            :@postings,
            :$silo
        );

    # find entry postings affecting silo ASSETS, entity base currency only
    my AssetCode $entity_base_currency = $GLOBAL::conf.resolve_base_currency(
        $!entity_name
    );
    my Regex $asset_code = /$entity_base_currency/;
    my Nightscape::Entry::Posting @postings_assets_silo_base_currency =
        Nightscape::Entry.ls_postings(
            :@postings,
            :$asset_code,
            :$silo
        );

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
        my Rat $d = ($incs // 0.0) - ($decs // 0.0);

        # asset flow: acquire / expend
        my AssetFlow $asset_flow = Nightscape::Types.mkasset_flow($d);

        # asset quantity
        my Quantity $quantity = $d.abs;

        # asset costing method
        my Costing $costing = $GLOBAL::conf.resolve_costing(
            :asset_code($aux_asset_code),
            :$!entity_name
        );

        # prepare cost basis data
        my Date $date = $entry.header.date;
        my Price $price = @p[0].amount.exchange_rate.asset_quantity;

        # build mod_holdings
        %mod_holdings{$aux_asset_code} = Nightscape::Transaction::ModHolding.new(
            :asset_code($aux_asset_code),
            :$asset_flow,
            :$costing,
            :$date,
            :$price,
            :$quantity
        );
    }

    # build transaction
    Nightscape::Transaction.new(
        :$uuid,
        :%mod_holdings,
        :@mod_wallet
    );
}

method mod_holdings(
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
        %!holdings{$asset_code}.acquire(
            :$date,
            :$price,
            :$quantity
        );
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
        %!holdings{$asset_code}.expend(
            :$uuid,
            :$costing,
            :$price,
            :$quantity
        );
    }
    # stable?
    elsif $asset_flow ~~ STABLE
    {
        # no change, likely an intra-entity asset transfer
    }
}

method mod_wallet(
    AssetCode :$asset_code!,
    DecInc :$decinc!,
    Quantity :$quantity!,
    Silo :$silo!,
    :@subwallet! # Constraint type check failed for parameter '@subwallet'
)
{
    # ensure $silo wallet exists (potential side effect)
    unless %!wallet{$silo}
    {
        %!wallet{$silo} = Nightscape::Entity::Wallet.new;
    }

    # dec/inc wallet balance (potential side effect)
    &deref(%!wallet{$silo}, @subwallet).set_balance(
        :$asset_code,
        :$decinc,
        :$quantity
    );
}

# execute transaction
method transact(
    Nightscape::Transaction :$transaction!
)
{
    # uuid
    my UUID $uuid = $transaction.uuid;

    # mod wallet balances
    my Nightscape::Transaction::ModWallet @mod_wallet = $transaction.mod_wallet;
    for @mod_wallet -> $mod_wallet
    {
        my AssetCode $asset_code = $mod_wallet.asset_code;
        my DecInc $decinc = $mod_wallet.decinc;
        my Quantity $quantity = $mod_wallet.quantity;
        my Silo $silo = $mod_wallet.silo;
        my VarName @subwallet = $mod_wallet.subwallet;

        self.mod_wallet(
            :$asset_code,
            :$decinc,
            :$quantity,
            :$silo,
            :@subwallet
        );
    }

    # mod holdings (only needed for entries dealing in aux assets)
    my Nightscape::Transaction::ModHolding %mod_holdings{AssetCode} =
        $transaction.mod_holdings;
    if %mod_holdings
    {
        for %mod_holdings.kv -> $asset_code, $mod_holdings
        {
            my AssetFlow $asset_flow = $mod_holdings.asset_flow;
            my Costing $costing = $mod_holdings.costing;
            my Date $date = $mod_holdings.date;
            my Price $price = $mod_holdings.price;
            my Quantity $quantity = $mod_holdings.quantity;

            self.mod_holdings(
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
}

# vim: ft=perl6
