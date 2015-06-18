use v6;
use Nightscape::Types;
unit class Nightscape::Entity::Wallet;

# balance, indexed by asset code
has Rat %.balance{AssetCode};

# subwallet, indexed by name
has Nightscape::Entity::Wallet %.subwallet{VarName} is rw;

# get wallet balance, recursively
method get_balance(AssetCode :$asset_code!) returns Rat
{
    my Rat $balance = %!balance{$asset_code} // 0.0;

    # is there a subwallet?
    if %!subwallet
    {
        # add subwallet balance to $balance
        for %!subwallet.kv -> $name, $subwallet
        {
            $balance += $subwallet.get_balance(:$asset_code);
        }
    }

    $balance;
}

# set wallet balance
method set_balance(
    AssetCode :$asset_code!,
    DecInc :$decinc!,
    Quantity :$quantity!
)
{
    if $decinc
    {
        # increase balance
        %!balance{$asset_code} += $quantity;
    }
    else
    {
        # decrease balance
        %!balance{$asset_code} -= $quantity;
    }
}

# vim: ft=perl6
