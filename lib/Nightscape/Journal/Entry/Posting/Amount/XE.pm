use v6;
use Nightscape::Specs;
class Nightscape::Journal::Entry::Posting::Amount::XE;

has CommodityCode $.commodity_code;
has Rat $.commodity_quantity;
has Str $.commodity_symbol;

# vim: ft=perl6
