use v6;
use Nightscape::Dx::Coa;
use Nightscape::Dx::Entryʹ;
use Nightscape::Dx::Hodl;
use TXN::Parser::ParseTree;
unit class Ledgerʹ;

# C<Ledger> from which C<Ledger′> is derived
has Ledger:D $.ledger is required;
has Entryʹ:D @.entryʹ is required;
has Coa:D $.coa is required;
has Hodl:D $.hodl is required;

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
