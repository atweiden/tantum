use v6;
use Tantum::Hook;
use Tantum::Types;

my role Common
{...}

role Hook::Response[POSTING]
{
    also does Common;
}

role Hook::Response[ENTRY]
{
    also does Common;
}

role Hook::Response[LEDGER]
{
    also does Common;
}

role Hook::Response[COA]
{
    also does Common;
}

role Hook::Response[HODL]
{
    also does Common;
}

role Hook::Response[HOOK]
{
    also does Common;
}

my role Common
{
    # return value of Hook indexed by Hook type
    has Hash[Any,Hook:U] @.made is required;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
