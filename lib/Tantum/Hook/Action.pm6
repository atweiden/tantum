use v6;
use Tantum::Types;

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

role Hook::Action[POSTING]
{
    also does Introspection;
    multi method apply(|)
    {...}
}

role Hook::Action[ENTRY]
{
    also does Introspection;
    multi method apply(|)
    {...}
}

role Hook::Action[LEDGER]
{
    also does Introspection;
    multi method apply(|)
    {...}
}

role Hook::Action[COA]
{
    also does Introspection;
    multi method apply(|)
    {...}
}

role Hook::Action[HODL]
{
    also does Introspection;
    multi method apply(|)
    {...}
}

role Hook::Action[HOOK]
{
    # omit C<also does Introspection> to avoid infinite loops
    multi method apply(|)
    {...}
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
