use v6;
use Nightscape::Types;
unit class Nightscape::Entity::Wallet;

# balance, indexed by asset code
has Rat %.balance{AssetCode};

# subwallet, indexed by name
has Nightscape::Entity::Wallet %.subwallet{VarName} is rw;

# get wallet balance, recursively
method getbalance(AssetCode $asset_code) returns Rat
{
    my Rat $balance = self.balance{$asset_code} // 0.0;

    # is there a subwallet?
    if self.subwallet
    {
        # add subwallet balance to $balance
        for self.subwallet.kv -> $name, $subwallet
        {
            $balance += $subwallet.getbalance($asset_code);
        }
    }

    $balance;
}

# set wallet balance
method setbalance(
    AssetCode $asset_code,
    Quantity $asset_quantity,
    DecInc $decinc
)
{
    if $decinc
    {
        # increase balance
        %!balance{$asset_code} += $asset_quantity;
    }
    else
    {
        # decrease balance
        %!balance{$asset_code} -= $asset_quantity;
    }
}

# vim: ft=perl6
