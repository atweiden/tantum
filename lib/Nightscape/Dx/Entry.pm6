use v6;
use Nightscape::Dx::Coa;
use Nightscape::Dx::Hodl;
use TXN::Parser::ParseTree;
unit class Nightscape::Dx::Entry;

# C<Entry> from which C<Entryʹ> is derived
has Entry:D $.entry is required;
has Nightscape::Dx::Coa:D $.coa is required;
has Nightscape::Dx::Hodl:D $.hodl is required;

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
