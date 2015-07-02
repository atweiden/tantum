use v6;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::Holding::Taxes;

# causal entry's UUID
has UUID $.uuid;

# acquisition price of funds expended
has Price $.acquisition_price;

# average cost of holding being depleted at time of depletion
has Price $.avco_at_expenditure;

# capital gains
has Quantity $.capital_gains = 0.0;

# capital losses
has Quantity $.capital_losses = 0.0;

# vim: ft=perl6
