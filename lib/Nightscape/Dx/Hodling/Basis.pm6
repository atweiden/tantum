use v6;
use Nightscape::Dx::Hodling::Basis::Lot;
use TXN::Parser::Types;
unit role Hodling::Basis[AssetCode:D $asset-code];

has AssetCode:D $!asset-code = $asset-code;
has Nightscape::Dx::Hodling::Basis::Lot[$asset-code] @.lot is required;

method asset-code(::?CLASS:D: --> AssetCode:D)
{
    my AssetCode:D $asset-code = $!asset-code;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
