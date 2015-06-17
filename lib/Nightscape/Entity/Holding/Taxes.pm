use v6;
use Nightscape::Types;
unit class Nightscape::Entity::Holding::Taxes;

# capital gains
has Quantity $.capital_gains;

# capital losses
has Quantity $.capital_losses;

# vim: ft=perl6
