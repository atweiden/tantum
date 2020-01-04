use v6;
use Tantum::Hook;
use TXN::Parser::ParseTree;
use X::Tantum::Hook::Core::Entry;
unit class Hook::Core::Entry::IsBalanced;
also does Hook[ENTRY];

has Str:D $!name = 'Entry::IsBalanced';
has Str:D $!description = 'verify Entry is balanced';
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
        Entry:D $entry,
        |
    )
)
{
    my Bool:D $is-entry-balanced = apply(|c);
    my Capture:D $apply = \(|c, :$is-entry-balanced);
}

multi sub apply(
    Entry:D $entry where { is-entry-balanced($_).so },
    |
    --> Bool:D
)
{
    my Bool:D $is-entry-balanced = True;
}

multi sub apply(
    Entry:D $entry,
    |
    --> Nil
)
{
    die(X::Tantum::Hook::Core::Entry::NotBalanced.new(:$entry));
}

sub is-entry-balanced(Entry:D $entry --> Bool:D)
{
    # XXX NYI
    my Bool:D $is-entry-balanced = True;
}

multi method is-match(
    | (
        Entry:D $entry,
        Bool:D :is-entry-balanced($)!,
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
        Entry:D $entry
    )
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=raku foldmethod=marker foldlevel=0:
