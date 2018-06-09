use v6;
use Tantum::Dx::Hodling::Basis;
use TXN::Parser::Types;
unit role Hodling[AssetCode:D $asset-code];

has AssetCode:D $!asset-code = $asset-code;
has Hodling::Basis[$asset-code] $.basis is required;

method asset-code(::?CLASS:D: --> AssetCode:D)
{
    my AssetCode:D $asset-code = $!asset-code;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
