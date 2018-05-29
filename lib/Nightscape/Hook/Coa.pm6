use v6;
use Nightscape::Dx::Coa;
use Nightscape::Dx::Hodl;
use Nightscape::Hook;
use Nightscape::Types;
use TXN::Parser::ParseTree;
unit class Hook::Coa;
also does Hook[COA];

has Str:D $!name = 'Coa';
has Str:D $!description = 'catch-all hook for COA';
has Int:D $!priority = 0;
has Hook:U @!dependency;

method dependency(::?CLASS:D: --> Array[Hook:U])
{
    my Hook:U @dependency = @!dependency;
}

method description(::?CLASS:D: --> Str:D)
{
    my Str:D $description = $!description;
}

method name(::?CLASS:D: --> Str:D)
{
    my Str:D $name = $!name;
}

method priority(::?CLASS:D: --> Int:D)
{
    my Int:D $priority = $!priority;
}

multi method apply(
    | (
        Coa:D $c,
        Entry:D $entry,
        Hodl:D $hodl,
        *% (
            Hook:U :@applied,
            Coa:D :@carry
        )
    )
    --> Coa:D
)
{
    # clone new C<Coa> from old
    my Coa:D $coa = $c.clone;
}

method is-match(
    Coa:D $coa,
    Entry:D $entry,
    Hodl:D $hodl,
    *% (
        Hook:U :@applied,
        Coa:D :@carry
    )
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
