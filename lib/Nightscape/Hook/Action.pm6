use v6;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;

role Nightscape::Hook::Action[POSTING]
{
    method apply(
        Entry::Posting:D $posting,
        Coa:D $coa,
        Hodl:D $hodl
        --> Entry::Postingʹ:D
    )
    {...}
}

role Nightscape::Hook::Action[ENTRY]
{
    method apply(
        Entry:D $entry,
        Entry::Postingʹ:D @postingʹ
        --> Entryʹ:D
    )
    {...}
}

role Nightscape::Hook::Action[LEDGER]
{
    method apply()
    {...}
}

role Nightscape::Hook::Action[COA]
{
    method apply(
        Coa:D $coa,
        Entry::Posting:D $posting
        --> Coa:D
    )
    {...}
}

role Nightscape::Hook::Action[HODL]
{
    method apply()
    {...}
}

role Nightscape::Hook::Action[HOOK]
{
    method apply()
    {...}
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
