use v6;
use Nightscape::Dx::Hodling;

class Nightscape::Dx::Hodl
{
    has Hodling:D @.hodling is required;
}

sub EXPORT(--> Map:D)
{
    my %EXPORT = 'Hodl' => Nightscape::Dx::Hodl;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
