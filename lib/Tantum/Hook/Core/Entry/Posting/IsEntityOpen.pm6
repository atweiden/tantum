use v6;
use Tantum::Hook;
use Tantum::Types;
use TXN::Parser::ParseTree;
use X::Tantum::Hook::Core::Entry::Posting;
unit class Hook::Core::Entry::Posting::IsEntityOpen;
also does Hook[POSTING];

has Str:D $!name = 'Entry::Posting::IsEntityOpen';
has Str:D $!description = 'ensure entity is in an open state per config';
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
    my Bool:D $is-entity-open = apply(|c);
    my Capture:D $apply = \(|c, :$is-entity-open);
}

multi sub apply(
    Entry::Posting:D $posting where { $*config.is-entity-open($_).so },
    |
    --> Bool:D
)
{
    my Bool:D $is-entity-open = True;
}

multi sub apply(
    Entry::Posting:D $posting,
    |
    --> Nil
)
{
    die(X::Tantum::Hook::Core::Entry::Posting::EntityClosed.new(:$posting));
}

multi method is-match(
    | (
        Bool:D :$is-entity-open!,
        |
    )
    --> Bool:D
)
{
    # don't match if hook has matched/applied previously
    my Bool:D $is-match = False;
}

multi method is-match(
    |
    --> Bool:D
)
{
    # match by default
    my Bool:D $is-match = True;
}

# vim: set filetype=raku foldmethod=marker foldlevel=0:
