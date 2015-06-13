use v6;
use Nightscape::Types;
unit class Nightscape::Transaction::ModWallet;

# account
has Silo $.silo;
has VarName @.subwallet;

# amount
has AssetCode $.asset_code;
has DecInc $.decinc;
has Quantity $.quantity;

# vim: ft=perl6
