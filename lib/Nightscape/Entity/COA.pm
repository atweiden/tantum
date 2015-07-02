use v6;
use Nightscape::Entity::COA::Acct;
use Nightscape::Entity::Wallet;
use Nightscape::Types;
unit class Nightscape::Entity::COA;

# accounts indexed by acct name
has Nightscape::Entity::COA::Acct %.acct{AcctName};

# wallet including calculated realized capital gains, realized capital losses
has Nightscape::Entity::Wallet %.wllt{Silo};

# entity's overall assets handled
# entity's overall entry UUIDs handled
# entity's overall posting UUIDs handled

# entry UUIDs handled by acct
# posting UUIDs handled by acct

# vim: ft=perl6
