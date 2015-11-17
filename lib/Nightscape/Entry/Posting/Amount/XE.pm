use v6;
use Nightscape::Types;
unit class Nightscape::Entry::Posting::Amount::XE;

has AssetCode $.asset_code is required;
has Quantity $.asset_quantity is required;
has Str $.asset_symbol;

# vim: ft=perl6
