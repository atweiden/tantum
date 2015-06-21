use v6;
use Nightscape::Entity::Wallet::Changeset;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::Wallet;

# append-only list of balance changesets, indexed by asset code
has Array[Nightscape::Entity::Wallet::Changeset] %.balance{AssetCode};

# subwallet, indexed by name
has Nightscape::Entity::Wallet %.subwallet{VarName} is rw;

# get wallet balance
method get_balance(
    AssetCode :$asset_code!,      # get wallet balance for this asset code
    Str :$base_currency,          # (optional) request results in $base_currency
                                  # When typecheck: AssetCode => Constraint type check failed for parameter '$base_currency'
    Bool :$recursive              # (optional) recursively query subwallets
) returns Rat
{
    my Rat $balance;
    my Rat @deltas;

    # does this wallet have a balance for asset code?
    if %!balance{$asset_code}
    {
        # calculate balance (sum changeset balance deltas)
        for %!balance{$asset_code}.list -> $changeset
        {
            # convert balance into $base_currency?
            if $base_currency
            {
                # does posting's asset code match the requested base currency?
                if $changeset.balance_delta_asset_code ~~ $base_currency
                {
                    push @deltas, $changeset.balance_delta;
                }
                else
                {
                    # does delta exchange rate's asset code match the
                    # requested base currency?
                    my AssetCode $xeac = $changeset.xe_asset_code;
                    unless $xeac ~~ $base_currency
                    {
                        # error: exchange rate data missing from changeset
                        die qq:to/EOF/;
                        Sorry, suitable exchange rate was missing for base currency
                        in changeset:

                        「$changeset」

                        Changeset defaults to balance delta for asset code: 「$asset_code」
                        Changeset includes exchange rate for asset code: 「$xeac」
                        but you requested a result in asset code: 「$base_currency」

                        Asset code $xeac exchange rate data is sourced from
                        transaction journal entry posting's exchange rate.
                        This exchange rate should either be included in
                        the original transaction journal file, or from the
                        price data configured.
                        EOF
                    }

                    # multiply changeset default balance delta by exchange rate
                    my Rat $balance_delta =
                        $changeset.balance_delta * $changeset.xe_asset_quantity;

                    # use balance figure converted to $base_currency
                    push @deltas, $balance_delta;
                }

            }
            else
            {
                # default to using changeset's main balance delta
                # in asset code: 「Posting.amount.asset_code」
                push @deltas, $changeset.balance_delta;
            }
        }

        # sum balance deltas
        $balance = [+] @deltas;
    }
    else
    {
        # balance is zero
        $balance = 0.0;
    }


    # recurse?
    if $recursive
    {
        # is there a subwallet?
        if %!subwallet
        {
            # add subwallet balance to $balance
            for %!subwallet.kv -> $name, $subwallet
            {
                $balance += $subwallet.get_balance(
                    :$asset_code,
                    :$base_currency,
                    :recursive
                );
            }
        }
    }

    $balance;
}

# record balance update instruction
method mkchangeset(
    UUID :$posting_uuid!,
    AssetCode :$asset_code!,
    DecInc :$decinc!,
    Quantity :$quantity!,
    AssetCode :$xe_asset_code,
    Quantity :$xe_asset_quantity
)
{
    # INC?
    if $decinc ~~ INC
    {
        # balance +
        push %!balance{$asset_code}, Nightscape::Entity::Wallet::Changeset.new(
            :balance_delta($quantity),
            :balance_delta_asset_code($asset_code),
            :$posting_uuid,
            :$xe_asset_code,
            :$xe_asset_quantity
        );
    }
    # DEC?
    elsif $decinc ~~ DEC
    {
        # balance -
        push %!balance{$asset_code}, Nightscape::Entity::Wallet::Changeset.new(
            :balance_delta(-$quantity),
            :balance_delta_asset_code($asset_code),
            :$posting_uuid,
            :$xe_asset_code,
            :$xe_asset_quantity
        );
    }
}

# vim: ft=perl6
