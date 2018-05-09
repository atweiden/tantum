use v6;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;

role Nightscape::Hook::Trigger[POSTING]
{
    method is-match(
        Entry::Posting:D $posting,
        Coa:D $coa,
        Hodl:D $hodl
        --> Bool:D
    )
    {...}
}

role Nightscape::Hook::Trigger[ENTRY]
{
    method is-match(
        Entry:D $entry,
        Entry::Postingʹ:D @postingʹ
        --> Bool:D
    )
    {...}
}

role Nightscape::Hook::Trigger[LEDGER]
{
    method is-match(
        --> Bool:D
    )
    {...}
}

role Nightscape::Hook::Trigger[COA]
{
    method is-match(
        Coa:D $coa,
        Entry::Posting:D $posting
        --> Bool:D
    )
    {...}
}

role Nightscape::Hook::Trigger[HODL]
{
    method is-match(
        --> Bool:D
    )
    {...}
}

role Nightscape::Hook::Trigger[HOOK]
{
    method is-match(
        --> Bool:D
    )
    {...}
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
