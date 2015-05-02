use v6;
use Nightscape::Journal::Entry::Posting::Amount::XE;
use Nightscape::Specs;
class Nightscape::Journal::Entry::Posting::Amount;

has CommodityCode $.commodity_code;
has Str $.commodity_minus;
has Rat $.commodity_quantity;
has Str $.commodity_symbol;
has Nightscape::Journal::Entry::Posting::Amount::XE $.exchange_rate;

# vim: ft=perl6
