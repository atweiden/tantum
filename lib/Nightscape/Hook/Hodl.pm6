use v6;
use Nightscape::Dx;
use Nightscape::Hook;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
unit class Nightscape::Hook::Hodl;
also does Nightscape::Hook[HODL];

has Str:D $!name = 'Hodl';
has Str:D $!description = 'catch-all hook for HODL';
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
        Hodl:D $h,
        Entryʹ:D $entryʹ
    )
    --> Hodl:D
)
{
    my Hodl:D $hodl = apply($h, $entryʹ);
}

multi sub apply(
    Hodl:D $h,
    Entryʹ:D $entryʹ where { has-aux-asset($_) }
    --> Hodl:D
)
{*}

sub has-aux-asset(Entryʹ:D $entryʹ --> Bool:D)
{*}

method is-match(
    Hodl:D $hodl,
    Entryʹ:D $entryʹ
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
