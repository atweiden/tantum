use v6;
use Tantum::Dx::Coa;
use Tantum::Dx::Entry;
use Tantum::Dx::Hodl;
use TXN::Parser::ParseTree;
unit class Ledgerʹ;

# C<Ledger> from which C<Ledgerʹ> is derived
has Ledger:D $.ledger is required;
has Entryʹ:D @.entryʹ is required;
has Coa:D $.coa is required;
has Hodl:D $.hodl is required;

# vim: set filetype=raku foldmethod=marker foldlevel=0:
