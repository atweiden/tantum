use v6;
use Nightscape::Specs;
class Nightscape::Entity::Wallet;

# balance, indexed by commodity code
has Rat %.balance{CommodityCode};

# subwallet, indexed by name
has Nightscape::Entity::Wallet %.subwallet{VarName} is rw;

# get wallet balance, recursively
method getbalance(CommodityCode $commodity_code) returns Rat
{
    my Rat $balance = self.balance{$commodity_code} // 0;

    # is there a subwallet?
    if self.subwallet
    {
        # add subwallet balance to $balance
        for self.subwallet.kv -> $name, $subwallet
        {
            $balance += $subwallet.getbalance($commodity_code);
        }
    }

    $balance;
}

# set wallet balance
method setbalance(
    CommodityCode $commodity_code,
    Quantity $commodity_quantity,
    DrCr $drcr
)
{
    if $drcr
    {
        # credit: increase balance
        %!balance{$commodity_code} += $commodity_quantity;
    }
    else
    {
        # debit: decrease balance
        %!balance{$commodity_code} -= $commodity_quantity;
    }
}

# vim: ft=perl6
