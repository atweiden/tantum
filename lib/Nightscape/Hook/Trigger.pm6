use v6;
use Nightscape::Dx;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;

role Nightscape::Hook::Trigger[POSTING]
{
    method is-match(
        Entry::Posting:D $posting,
        Entry::Header:D $header
        --> Bool:D
    )
    {...}
}

role Nightscape::Hook::Trigger[ENTRY]
{
    method is-match(
        Entry:D $entry,
        Coa:D $coa,
        Hodl:D $hodl
        --> Bool:D
    )
    {...}
}

role Nightscape::Hook::Trigger[LEDGER]
{
    method is-match(
        Ledger:D $ledger,
        Coa:D $coa,
        Hodl:D $hodl
        --> Bool:D
    )
    {...}
}

role Nightscape::Hook::Trigger[COA]
{
    method is-match(
        Coa:D $coa,
        Entry:D $entry,
        Hodl:D $hodl
        --> Bool:D
    )
    {...}
}

role Nightscape::Hook::Trigger[HODL]
{
    method is-match(
        Hodl:D $hodl,
        Entry:D $entry
        --> Bool:D
    )
    {...}
}

role Nightscape::Hook::Trigger[HOOK]
{
    method is-match(
        Str:D $class-name,
        Str:D $routine-name,
        Capture:D $capture
        --> Bool:D
    )
    {...}
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
