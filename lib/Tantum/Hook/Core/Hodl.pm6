use v6;
use Tantum::Dx::Hodl;
use Tantum::Hook;
use Tantum::Types;
use TXN::Parser::ParseTree;
unit class Hook::Core::Hodl;
also does Hook[HODL];

has Str:D $!name = 'Hodl';
has Str:D $!description = 'core hook for HODL';
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
        Hodl:D $h,
        Entry:D $entry,
        *% (
            Hook:U :@applied,
            Hodl:D :@carry
        )
    )
)
{
    my Hodl:D $hodl = apply($h, $entry);
}

multi sub apply(
    Hodl:D $h,
    Entry:D $entry where { .&has-aux-asset }
    --> Hodl:D
)
{*}

sub has-aux-asset(Entry:D $entry --> Bool:D)
{*}

multi method is-match(
    | (
        Hodl:D $hodl,
        Entry:D $entry,
        *% (
            Hook:U :@applied! where .so,
            Hodl:D :@carry
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
        Hodl:D $hodl,
        Entry:D $entry,
        *% (
            Hook:U :@applied,
            Hodl:D :@carry
        )
    )
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=raku foldmethod=marker foldlevel=0:
