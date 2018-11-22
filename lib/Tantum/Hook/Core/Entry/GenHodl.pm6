use v6;
use Tantum::Dx::Entry;
use Tantum::Hook;
unit class Hook::Core::Entry::GenHodl;
also does Hook[ENTRY];

has Str:D $!name = 'Entry::GenHodl';
has Str:D $!description =
    'generate Hodl from Entryʹ and any previously generated Hodl';
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
    |c (
        Entryʹ:D $entryʹ,
        Hodl:D $hodl,
        |
    )
)
{
    my Capture:D $capture = apply(|c);
}

sub apply(
    Entryʹ:D $entryʹ,
    Hodl:D $hodl,
    |
    --> Capture:D
)
{
    # XXX: NYI
    my Capture:D $capture = \($entryʹ, $hodl, :gen-hodl);
}

multi method is-match(
    | (
        Bool:D :gen-hodl($)! where .so
        |
    )
    --> Bool:D
)
{
    # don't match if hook has matched/applied previously
    my Bool:D $is-match = False;
}

multi method is-match(
    | (
        Entryʹ:D $entryʹ,
        Hodl:D $hodl,
        |
    )
    --> Bool:D
)
{
    # match when passed C<Hodl> instance
    my Bool:D $is-match = True;
}

multi method is-match(
    | (
        Entryʹ:D $entryʹ,
        |
    )
    --> Bool:D
)
{
    # match when not passed C<Hodl> instance
    my Bool:D $is-match = True;
}

multi method is-match(
    |
    --> Bool:D
)
{
    # don't match by default
    my Bool:D $is-match = False;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
