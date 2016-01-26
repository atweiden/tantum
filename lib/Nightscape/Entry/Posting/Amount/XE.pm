use v6;
use Nightscape::Types;
unit class Nightscape::Entry::Posting::Amount::XE;

has AssetCode $.asset-code is required;
has Quantity $.asset-quantity is required;
has Str $.asset-symbol;

# vim: ft=perl6
