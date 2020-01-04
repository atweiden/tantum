use v6;
use Tantum::Dx::Hodling;
use TXN::Parser::Types;
unit class Hodl;

has Hodling:D %.hodling{AssetCode:D} is required;

# vim: set filetype=raku foldmethod=marker foldlevel=0:
