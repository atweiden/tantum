use v6;
use Nightscape::Transaction::ModHolding;
use Nightscape::Transaction::ModWallet;
use Nightscape::Types;
use UUID;
unit class Nightscape::Transaction;

# source entry uuid
has UUID $.uuid;

# holdings acquisitions and expenditures indexed by asset, in entry
has Nightscape::Transaction::ModHolding %.mod_holdings{AssetCode};

# wallet balance modification instructions per posting, in entry
has Nightscape::Transaction::ModWallet @.mod_wallet;

# vim: ft=perl6
