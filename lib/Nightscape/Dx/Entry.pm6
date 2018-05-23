use v6;
use Nightscape::Dx::Coa;
use Nightscape::Dx::Hodl;
use TXN::Parser::ParseTree;

class Nightscape::Dx::Entry
{
    # C<Entry> from which C<Entryʹ> is derived
    has Entry:D $.entry is required;
    has Coa:D $.coa is required;
    has Hodl:D $.hodl is required;
}

sub EXPORT(--> Map:D)
{
    my %EXPORT = 'Entryʹ' => Nightscape::Dx::Entry;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
