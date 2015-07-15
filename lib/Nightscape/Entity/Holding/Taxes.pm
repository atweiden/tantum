use v6;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::Holding::Taxes;

# causal entry's UUID
has UUID $.uuid;

# acquisition price of funds expended
has Price $.acquisition_price;

# asset code of acquisition price
has AssetCode $.acquisition_price_asset_code;

# average cost of holding being depleted at time of depletion
has Price $.avco_at_expenditure;

# capital gains
has Quantity $.capital_gains = 0.0;

# capital losses
has Quantity $.capital_losses = 0.0;

# quantity expended of holding in the making of this Taxes instance
has Quantity $.quantity_expended;

# asset code of quantity expended
has AssetCode $.quantity_expended_asset_code;

# vim: ft=perl6
