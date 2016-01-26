use v6;
use Nightscape::Types;
unit class Nightscape::Entity::TXN::ModHolding;

# parent entity
has VarName $.entity is required;

# holding asset code
has AssetCode $.asset-code is required;

# acquire / expend
has AssetFlow $.asset-flow is required;

# inventory costing method for asset
has Costing $.costing is required;

# date of acquisition / expenditure
has DateTime $.date is required;

# acquisition price / expend price
has Price $.price is required;

# asset code of acquisition price
has AssetCode $.acquisition-price-asset-code is required;

# quantity to acquire / expend
has Quantity $.quantity is required;

# vim: ft=perl6
