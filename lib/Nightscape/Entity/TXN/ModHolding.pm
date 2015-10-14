use v6;
use Nightscape::Types;
unit class Nightscape::Entity::TXN::ModHolding;

# parent entity
has VarName $.entity;

# holding asset code
has AssetCode $.asset_code;

# acquire / expend
has AssetFlow $.asset_flow;

# inventory costing method for asset
has Costing $.costing;

# date of acquisition / expenditure
has DateTime $.date;

# acquisition price / expend price
has Price $.price;

# asset code of acquisition price
has AssetCode $.acquisition_price_asset_code;

# quantity to acquire / expend
has Quantity $.quantity;

# vim: ft=perl6
