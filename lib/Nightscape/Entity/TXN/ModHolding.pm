use v6;
use Nightscape::Types;
unit class Nightscape::Entity::TXN::ModHolding;

# holding asset code
has AssetCode $.asset_code;

# acquire / expend
has AssetFlow $.asset_flow;

# inventory costing method for asset
has Costing $.costing;

# date of acquisition / expenditure
has Date $.date;

# acquisition price / expend price
has Price $.price;

# quantity to acquire / expend
has Quantity $.quantity;

# vim: ft=perl6
