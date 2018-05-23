use v6;
use Nightscape::Dx::Coa;
use Nightscape::Dx::Entry;
use Nightscape::Dx::Hodl;
use TXN::Parser::ParseTree;
unit class Nightscape::Dx::Ledger;

# C<Ledger> from which C<Ledgerʹ> is derived
has Ledger:D $.ledger is required;
has Nightscape::Dx::Entry:D @.entryʹ is required;
has Nightscape::Dx::Coa:D $.coa is required;
has Nightscape::Dx::Hodl:D $.hodl is required;

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
