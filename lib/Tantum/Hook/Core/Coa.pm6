use v6;
use Tantum::Dx::Coa;
use Tantum::Dx::Hodl;
use Tantum::Hook;
use Tantum::Types;
use TXN::Parser::ParseTree;
unit class Hook::Core::Coa;
also does Hook[COA];

has Str:D $!name = 'Coa';
has Str:D $!description = 'core hook for COA';
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
)
{
    # clone new C<Coa> from old
    my Coa:D $coa = $c.clone;
}

multi method is-match(
    | (
        Coa:D $coa,
        Entry:D $entry,
        Hodl:D $hodl,
        *% (
            Hook:U :@applied! where .so,
            Coa:D :@carry
        )
    )
    --> Bool:D
)
{
    # don't match if hook has matched/applied previously
    my Bool:D $is-match = False;
}

multi method is-match(
    | (
        Coa:D $coa,
        Entry:D $entry,
        Hodl:D $hodl,
        *% (
            Hook:U :@applied,
            Coa:D :@carry
        )
    )
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=raku foldmethod=marker foldlevel=0:
