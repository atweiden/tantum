use v6;
use Nightscape::Types;
unit class Nightscape::Entity::Holding::Basis::Depletion;

# quantity of holding depleted
has Quantity $.quantity is required;

# causal EntryID of this depletion
has EntryID $.entry-id is required;

# date of acquisition of holding being depleted
has DateTime $.acquisition-date is required;

# acquisition price of holding being depleted
has Price $.acquisition-price is required;

# asset code of acquisition price
has AssetCode $.acquisition-price-asset-code is required;

# average cost of holding being depleted at time of depletion
has Price $.avco-at-expenditure is required;

# date of expenditure
has DateTime $.date-of-expenditure is required;

# vim: ft=perl6
