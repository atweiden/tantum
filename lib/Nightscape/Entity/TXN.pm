use v6;
use Nightscape::Entity::TXN::ModHolding;
use Nightscape::Entity::TXN::ModWallet;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::TXN;

# causal entry uuid
has UUID $.uuid;

# holdings acquisitions and expenditures indexed by asset, in entry
has Nightscape::Entity::TXN::ModHolding %.mod_holdings{AssetCode};

# wallet balance modification instructions per posting, in entry
has Nightscape::Entity::TXN::ModWallet @.mod_wallet;

# vim: ft=perl6
