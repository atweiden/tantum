use v6;
use Nightscape::Types;
unit class Nightscape::Config::Pricesheet;

has Hash[Price,Date] %.prices{AssetCode};

# vim: ft=perl6
