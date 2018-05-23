use v6;
use Nightscape::Dx::Coa;
use Nightscape::Dx::Hodl;
use TXN::Parser::ParseTree;
unit class Entryʹ;

# C<Entry> from which C<Entryʹ> is derived
has Entry:D $.entry is required;
has Coa:D $.coa is required;
has Hodl:D $.hodl is required;

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
