use v6;
use Tantum::Hook;
use Tantum::Types;
unit class Hook::Hook;
also does Hook[HOOK];

has Str:D $!name = 'Hook';
has Str:D $!description = 'catch-all hook for HOOK';
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
        @arg ('enter', Str:D $, Str:D $, Capture:D $),
        *% (Hook:U :@applied)
    )
    --> Nil
)
{
    my Str:D $apply = apply(@arg);
    my Str:D $msg = sprintf(Q{[ENTER] %s}, $apply);
}

multi method apply(
    | (
        @arg ('leave', Str:D $, Str:D $, Capture:D $),
        *% (Hook:U :@applied)
    )
    --> Nil
)
{
    my Str:D $apply = apply(@arg);
    my Str:D $msg = sprintf(Q{[LEAVE] %s}, $apply);
}

sub apply(
    @ (
        Str:D $enter-leave,
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

multi method is-match(
    Str:D $enter-leave,
    Str:D $class-name,
    Str:D $routine-name,
    Capture:D $capture,
    *% (Hook:U :@applied! where .so)
    --> Bool:D
)
{
    # don't match if hook has matched/applied previously
    my Bool:D $is-match = False;
}

multi method is-match(
    Str:D $enter-leave,
    Str:D $class-name,
    Str:D $routine-name,
    Capture:D $capture,
    *% (Hook:U :@applied)
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
