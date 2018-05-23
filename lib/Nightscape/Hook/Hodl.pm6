use v6;
use Nightscape::Dx::Hodl;
use Nightscape::Hook;
use Nightscape::Types;
use TXN::Parser::ParseTree;
unit class Nightscape::Hook::Hodl;
also does Nightscape::Hook[HODL];

has Str:D $!name = 'Hodl';
has Str:D $!description = 'catch-all hook for HODL';
has Int:D $!priority = 0;
has Nightscape::Hook:U @!dependency;

method dependency(::?CLASS:D: --> Array[Nightscape::Hook:U])
{
    my Nightscape::Hook:U @dependency = @!dependency;
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
        Entry:D $entry
    )
    --> Hodl:D
)
{
    my Hodl:D $hodl = apply($h, $entry);
}

multi sub apply(
    Hodl:D $h,
    Entry:D $entry where { has-aux-asset($_) }
    --> Hodl:D
)
{*}

sub has-aux-asset(Entry:D $entry --> Bool:D)
{*}

method is-match(
    Hodl:D $hodl,
    Entry:D $entry
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
