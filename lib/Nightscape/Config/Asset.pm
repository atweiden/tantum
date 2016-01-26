use v6;
use Nightscape::Types;
unit class Nightscape::Config::Asset;

# asset code
has AssetCode $.asset-code is required;

# inventory valuation method (AVCO, FIFO, LIFO)
has Costing $.costing;

# price data
has Hash[Price,DateTime] %.prices{AssetCode};

# vim: ft=perl6
