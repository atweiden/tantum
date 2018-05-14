use v6;
use Nightscape::Dx;
use Nightscape::Registry;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
unit class Nightscape::Hook::Coa;
also does Nightscape::Hook[COA];

has Str:D $!name = 'Coa';
has Str:D $!description = 'catch-all hook for COA';
has Int:D $!priority = 0;
has Nightscape::Hook:U @!dependency;

method name(::?CLASS:D: --> Str:D)
{
    my Str:D $name = $!name;
}

method description(::?CLASS:D: --> Str:D)
{
    my Str:D $description = $!description;
}

method dependency(::?CLASS:D: --> Array[Nightscape::Hook:U])
{
    my Nightscape::Hook:U @dependency = @!dependency;
}

method priority(::?CLASS:D: --> Int:D)
{
    my Int:D $priority = $!priority;
}

multi method apply(
    | (
        Coa:D $c,
        Entry:D $entry
    )
    --> Coa:D
)
{
    # clone new C<Coa> from old
    my Coa:D $coa = $c.clone;
}

method is-match(
    Coa:D $coa,
    Entry:D $entry
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
