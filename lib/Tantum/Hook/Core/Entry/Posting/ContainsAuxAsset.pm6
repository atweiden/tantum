use v6;
use Tantum::Hook;
use Tantum::Types;
use TXN::Parser::ParseTree;
unit class Hook::Core::Entry::Posting::ContainsAuxAsset;
also does Hook[POSTING];

has Str:D $!name = 'Entry::Posting::ContainsAuxAsset';
has Str:D $!description = 'check if posting contains aux asset';
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
        Entry::Posting:D $posting,
        |
    )
)
{
    my Bool:D $contains-aux-asset = apply(|c);
    my Capture:D $apply = \(|c, :$contains-aux-asset);
}

multi sub apply(
    Entry::Posting:D $posting where { $*config.contains-aux-asset($_).so },
    |
    --> Bool:D
)
{
    my Bool:D $contains-aux-asset = True;
}

multi sub apply(
    Entry::Posting:D $posting,
    |
    --> Bool:D
)
{
    my Bool:D $contains-aux-asset = False;
}

multi method is-match(
    | (
        Bool:D :$contains-aux-asset!,
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
        Bool:D :$is-entity-open! where .so,
        Bool:D :$is-account-open! where .so,
        |
    )
    --> Bool:D
)
{
    # match once we're sure entity/account are open
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

# vim: set filetype=raku foldmethod=marker foldlevel=0:
