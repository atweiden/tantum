use v6;
use Tantum::Hook;
use Tantum::Types;
use TXN::Parser::ParseTree;
use X::Tantum::Hook::Core::Entry::Posting;
unit class Hook::Core::Entry::Posting::IsAccountOpen;
also does Hook[POSTING];

has Str:D $!name = 'Entry::Posting::IsAccountOpen';
has Str:D $!description = 'ensure account is in an open state per config';
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
    my Bool:D $is-account-open = apply(|c);
}

multi sub apply(
    | (
        Entry::Posting:D $posting where { $*config.is-account-open($_).so },
        |
    )
)
{
    my Bool:D $is-account-open = True;
}

multi sub apply(
    | (
        Entry::Posting:D $posting,
        |
    )
)
{
    die(X::Tantum::Hook::Core::Entry::Posting::AccountClosed.new(:$posting));
}

multi method is-match(
    | (
        Bool:D :$is-account-open!,
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
        |
    )
    --> Bool:D
)
{
    # match once we're sure entity is open
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
