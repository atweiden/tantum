use v6;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::Holding::Basis::Depletion;

# quantity of holding depleted
has Quantity $.quantity;

# causal entry's UUID of this depletion
has UUID $.uuid;

# acquisition price of holding being depleted
has Price $.acquisition_price;

# average cost of holding being depleted at time of depletion
has Price $.avco_at_expenditure;

# vim: ft=perl6
