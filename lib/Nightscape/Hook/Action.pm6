use v6;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;

my role Apply
{
    proto method apply(|c)
    {
        my Str:D $class-name = ::?CLASS.^name;
        my Str:D $routine-name = &?ROUTINE.name;
        my @arg = $class-name, $routine-name, c;
        LEAVE { $registry.send-to-hooks(HOOK, :finish, @arg); }
        $registry.send-to-hooks(HOOK, :start, @arg);
        {*}
    }
}

role Nightscape::Hook::Action[POSTING]
{
    also does Apply;

    multi method apply(
        | (
            Entry::Posting:D $posting,
            Coa:D $coa,
            Hodl:D $hodl
        )
        --> Entry::Postingʹ:D
    )
    {...}

    multi method apply(
        | (
            Entry::Postingʹ:D $postingʹ
        )
        --> Entry::Postingʹ:D
    )
    {...}
}

role Nightscape::Hook::Action[ENTRY]
{
    also does Apply;

    multi method apply(
        | (
            Entry:D $entry,
            Entry::Postingʹ:D @postingʹ
        )
        --> Entryʹ:D
    )
    {...}

    multi method apply(
        | (
            Entryʹ:D $entryʹ
        )
        --> Entryʹ:D
    )
    {...}
}

role Nightscape::Hook::Action[LEDGER]
{
    also does Apply;

    multi method apply(|)
    {...}
}

role Nightscape::Hook::Action[COA]
{
    also does Apply;

    multi method apply(
        | (
            Coa:D $coa,
            Entry::Posting:D $posting
        )
        --> Coa:D
    )
    {...}
}

role Nightscape::Hook::Action[HODL]
{
    also does Apply;

    multi method apply(|)
    {...}
}

role Nightscape::Hook::Action[HOOK]
{
    # intentional omission of C<also does Apply> avoids infinite loops
    method apply()
    {...}
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
