use v6;
use Nightscape::Dx::Coa;
use Nightscape::Dx::Entry;
use Nightscape::Dx::Hodl;
use TXN::Parser::ParseTree;

class Nightscape::Dx::Ledger
{
    # C<Ledger> from which C<Ledgerʹ> is derived
    has Ledger:D $.ledger is required;
    has Entryʹ:D @.entryʹ is required;
    has Coa:D $.coa is required;
    has Hodl:D $.hodl is required;
}

sub EXPORT(--> Map:D)
{
    my %EXPORT = 'Ledgerʹ' => Nightscape::Dx::Ledger;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
