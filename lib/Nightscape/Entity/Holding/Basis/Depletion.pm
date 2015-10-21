use v6;
use Nightscape::Types;
unit class Nightscape::Entity::Holding::Basis::Depletion;

# quantity of holding depleted
has Quantity $.quantity;

# causal EntryID of this depletion
has EntryID $.entry_id;

# date of acquisition of holding being depleted
has DateTime $.acquisition_date;

# acquisition price of holding being depleted
has Price $.acquisition_price;

# asset code of acquisition price
has AssetCode $.acquisition_price_asset_code;

# average cost of holding being depleted at time of depletion
has Price $.avco_at_expenditure;

# date of expenditure
has DateTime $.date_of_expenditure;

# vim: ft=perl6
