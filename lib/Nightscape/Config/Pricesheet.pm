use v6;
use Nightscape::Types;
unit class Nightscape::Config::Pricesheet;

has Hash[Price,Date] %.prices{CommodityCode};

# vim: ft=perl6
