use v6;
use Nightscape::Dx;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
unit class Nightscape::Hook::Hook;
also does Nightscape::Hook[HOOK];

has Str:D $!name = 'Hook';
has Str:D $!description = 'catch-all hook for HOOK';
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
    @arg (
        Str:D $,
        Str:D $,
        Capture:D $
    ),
    Bool:D :enter($)! where .so
    --> Nil
)
{
    my Str:D $apply = apply(@arg);
    my Str:D $msg = sprintf(Q{[ENTER] %s}, $apply);
}

multi method apply(
    @arg (
        Str:D $,
        Str:D $,
        Capture:D $
    ),
    Bool:D :leave($)! where .so
    --> Nil
)
{
    my Str:D $apply = apply(@arg);
    my Str:D $msg = sprintf(Q{[LEAVE] %s}, $apply);
}

sub apply(
    @ (
        Str:D $class-name,
        Str:D $routine-name,
        Capture:D $capture
    )
    --> Str:D
)
{
    my Str:D $apply =
        sprintf(Q{%s.%s: %s}, $class-name, $routine-name, $capture.perl);
}

method is-match(| --> Bool:D)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
