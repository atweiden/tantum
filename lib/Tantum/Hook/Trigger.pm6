use v6;
use Tantum::Types;

role Hook::Trigger[POSTING]
{
    multi method is-match(| --> Bool:D)
    {...}
}

role Hook::Trigger[ENTRY]
{
    multi method is-match(| --> Bool:D)
    {...}
}

role Hook::Trigger[LEDGER]
{
    multi method is-match(| --> Bool:D)
    {...}
}

role Hook::Trigger[COA]
{
    multi method is-match(| --> Bool:D)
    {...}
}

role Hook::Trigger[HODL]
{
    multi method is-match(| --> Bool:D)
    {...}
}

role Hook::Trigger[HOOK]
{
    multi method is-match(| --> Bool:D)
    {...}
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
