use v6;
use Nightscape::Entry::Posting::Amount::XE;
use Nightscape::Types;
unit class Nightscape::Entry::Posting::Amount;

has AssetCode $.asset_code;
has Quantity $.asset_quantity;
has Str $.asset_symbol;
has Str $.minus_sign;
has Nightscape::Entry::Posting::Amount::XE $.exchange_rate is rw;

# vim: ft=perl6
