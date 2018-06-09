use v6;
use Tantum::Dx::Coa;
use Tantum::Dx::Entry::Posting;
use Tantum::Dx::Entry;
use Tantum::Dx::Hodl;
use Tantum::Dx::Ledger;
use Tantum::Types;
use TXN::Parser::ParseTree;

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

    multi method apply(
        | (
            Entry::Posting:D $posting,
            Entry::Header:D $header,
            *%opts (
                :@applied,
                Entry::Postingʹ:D :@carry
            )
        )
        --> Entry::Postingʹ:D
    )
    {...}
}

role Hook::Action[ENTRY]
{
    also does Introspection;

    multi method apply(
        | (
            Entry:D $entry,
            Coa:D $coa,
            Hodl:D $hodl,
            *%opts (
                :@applied,
                Entryʹ:D :@carry
            )
        )
        --> Entryʹ:D
    )
    {...}
}

role Hook::Action[LEDGER]
{
    also does Introspection;

    multi method apply(
        | (
            Ledger:D $ledger,
            Coa:D $coa,
            Hodl:D $hodl,
            *%opts (
                :@applied,
                Ledgerʹ:D :@carry
            )
        )
        --> Ledgerʹ:D
    )
    {...}
}

role Hook::Action[COA]
{
    also does Introspection;

    multi method apply(
        | (
            Coa:D $coa,
            Entry:D $entry,
            Hodl:D $hodl,
            *%opts (
                :@applied,
                Coa:D :@carry
            )
        )
        --> Coa:D
    )
    {...}
}

role Hook::Action[HODL]
{
    also does Introspection;

    multi method apply(
        | (
            Hodl:D $hodl,
            Entry:D $entry,
            *%opts (
                :@applied,
                Hodl:D :@carry
            )
        )
        --> Hodl:D
    )
    {...}
}

role Hook::Action[HOOK]
{
    # omit C<also does Introspection> to avoid infinite loops
    method apply(
        | (
            Str:D $enter-leave,
            Str:D $class-name,
            Str:D $routine-name,
            Capture:D $capture,
            *%opts (
                :@applied
            )
        )
        --> Nil
    )
    {...}
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
