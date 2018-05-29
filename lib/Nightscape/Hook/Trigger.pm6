use v6;
use Nightscape::Dx::Coa;
use Nightscape::Dx::Entry::Posting;
use Nightscape::Dx::Entry;
use Nightscape::Dx::Hodl;
use Nightscape::Dx::Ledger;
use Nightscape::Types;
use TXN::Parser::ParseTree;

role Hook::Trigger[POSTING]
{
    method is-match(
        Entry::Posting:D $posting,
        Entry::Header:D $header,
        *%opts (
            :@applied,
            Entry::Postingʹ:D :@carry
        )
        --> Bool:D
    )
    {...}
}

role Hook::Trigger[ENTRY]
{
    method is-match(
        Entry:D $entry,
        Coa:D $coa,
        Hodl:D $hodl,
        *%opts (
            :@applied,
            Entryʹ:D :@carry
        )
        --> Bool:D
    )
    {...}
}

role Hook::Trigger[LEDGER]
{
    method is-match(
        Ledger:D $ledger,
        Coa:D $coa,
        Hodl:D $hodl,
        *%opts (
            :@applied,
            Ledgerʹ:D :@carry
        )
        --> Bool:D
    )
    {...}
}

role Hook::Trigger[COA]
{
    method is-match(
        Coa:D $coa,
        Entry:D $entry,
        Hodl:D $hodl,
        *%opts (
            :@applied,
            Coa:D :@carry
        )
        --> Bool:D
    )
    {...}
}

role Hook::Trigger[HODL]
{
    method is-match(
        Hodl:D $hodl,
        Entry:D $entry,
        *%opts (
            :@applied,
            Hodl:D :@carry
        )
        --> Bool:D
    )
    {...}
}

role Hook::Trigger[HOOK]
{
    method is-match(
        Str:D $enter-leave,
        Str:D $class-name,
        Str:D $routine-name,
        Capture:D $capture,
        *%opts (
            :@applied
        )
        --> Bool:D
    )
    {...}
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
