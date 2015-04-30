use v6;
class Nightscape::Pricesheet;

subset Price of Rat is export where * > 0;

has Hash[Price,Date] %.prices{Str};

# vim: ft=perl6
