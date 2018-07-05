use v6;
use Tantum::Types;

my role Common
{...}

my role Introspection
{...}

role Hook::Action[POSTING]
{
    also does Common;
    also does Introspection;
}

role Hook::Action[ENTRY]
{
    also does Common;
    also does Introspection;
}

role Hook::Action[LEDGER]
{
    also does Common;
    also does Introspection;
}

role Hook::Action[COA]
{
    also does Common;
    also does Introspection;
}

role Hook::Action[HODL]
{
    also does Common;
    also does Introspection;
}

role Hook::Action[HOOK]
{
    also does Common;
    # omit C<Introspection> to avoid infinite loops
}

my role Common
{
    multi method apply(|)
    {...}
}

my role Introspection
{
    proto method apply(|c)
    {
        my Str:D $class-name = ::?CLASS.^name;
        my Str:D $routine-name = &?ROUTINE.name;
        my @arg = $class-name, $routine-name, c;
        LEAVE { $*registry.send-to-hooks(HOOK, ['leave', |@arg]); }
        # ENTER: https://github.com/rakudo/rakudo/issues/1815
        $*registry.send-to-hooks(HOOK, ['enter', |@arg]);
        {*}
    }
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
