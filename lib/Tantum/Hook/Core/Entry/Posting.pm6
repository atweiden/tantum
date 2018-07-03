use v6;
use Tantum::Hook;
use Tantum::Types;
use TXN::Parser::ParseTree;
unit class Hook::Core::Entry::Posting;
also does Hook[POSTING];

has Str:D $!name = 'Entry::Posting';
has Str:D $!description = 'core hook for POSTING';
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
        Entry::Posting:D $p,
        Entry::Header:D $header,
        *% (
            Hook:U :@applied,
            Entry::Postingʹ:D :@carry
        )
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

multi method is-match(
    Entry::Posting:D $posting,
    Entry::Header:D $header,
    *% (
        Hook:U :@applied! where .so,
        Entry::Postingʹ:D :@carry
    )
    --> Bool:D
)
{
    # don't match if hook has matched/applied previously
    my Bool:D $is-match = False;
}

multi method is-match(
    Entry::Posting:D $posting,
    Entry::Header:D $header,
    *% (
        Hook:U :@applied,
        Entry::Postingʹ:D :@carry
    )
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
