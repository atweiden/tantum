use v6;
use TXN::Parser::Types;
unit role Hodling::Basis::Lot[AssetCode:D $asset-code];

has AssetCode:D $!asset-code = $asset-code;
has Entry::ID:D $.entry-id is required;
has Date:D $.date is required;
has Price:D $.price is required;
has Quantity:D $.quantity is required;

method asset-code(::?CLASS:D: --> AssetCode:D)
{
    my AssetCode:D $asset-code = $!asset-code;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
