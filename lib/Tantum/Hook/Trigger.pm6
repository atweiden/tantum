use v6;
use Tantum::Types;

my role Common
{...}

role Hook::Trigger[POSTING]
{
    also does Common;
}

role Hook::Trigger[ENTRY]
{
    also does Common;
}

role Hook::Trigger[LEDGER]
{
    also does Common;
}

role Hook::Trigger[COA]
{
    also does Common;
}

role Hook::Trigger[HODL]
{
    also does Common;
}

role Hook::Trigger[HOOK]
{
    also does Common;
}

my role Common
{
    multi method is-match(| --> Bool:D)
    {...}
}

# vim: set filetype=raku foldmethod=marker foldlevel=0:
