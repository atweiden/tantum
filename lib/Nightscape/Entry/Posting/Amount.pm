use v6;
use Nightscape::Entry::Posting::Amount::XE;
use Nightscape::Types;
unit class Nightscape::Entry::Posting::Amount;

has CommodityCode $.commodity_code;
has Str $.commodity_minus;
has Quantity $.commodity_quantity;
has Str $.commodity_symbol;
has Nightscape::Entry::Posting::Amount::XE $.exchange_rate is rw;

# vim: ft=perl6
