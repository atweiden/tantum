use v6;
use Nightscape::Dx;
use Nightscape::Registry;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
unit class Nightscape::Hook::Entry::Posting;
also does Nightscape::Hook[POSTING];

has Str:D $!name = 'Entry::Posting';
has Str:D $!description = 'catch-all hook for POSTING';
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
        Entry::Posting:D $p
    )
    --> Entry::Posting:D
)
{
    my Entry::Posting:D $posting =
        $p
        # ensure entity is in an open state per config
        ==> apply(:is-entity-open)
        # ensure account is in an open state per config
        ==> apply(:is-account-open)
        # ensure config contains proper xe rate for aux assets
        ==> apply(:is-xe-present);
}

multi sub apply(
    Entry::Posting:D $posting,
    Bool:D :is-entity-open($)! where .so
    --> Entry::Posting:D
)
{
    $posting;
}

multi sub apply(
    Entry::Posting:D $posting,
    Bool:D :is-account-open($)! where .so
    --> Entry::Posting:D
)
{
    $posting;
}

multi sub apply(
    Entry::Posting:D $posting,
    Bool:D :is-xe-present($)! where .so
    --> Entry::Posting:D
)
{
    $posting;
}

method is-match(
    Entry::Posting:D $posting
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
