use v6;
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
    has $.made is required;

    proto method new(|)
    {*}

    multi method new(|c)
    {
        self.bless(:made(|c));
    }
}

# vim: set filetype=raku foldmethod=marker foldlevel=0:
