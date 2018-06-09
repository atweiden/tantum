use v6;
use Tantum::Dx::Account;
use Tantum::Dx::Coa;
use Tantum::Dx::Entry;
use Tantum::Dx::Entry::Posting;
use Tantum::Dx::Hodl;
use Tantum::Dx::Hodling;
use Tantum::Dx::Ledger;
use Tantum::Hook;
use Tantum::Types;

role Hook::Response[POSTING]
{
    has Hash[Entry::Postingʹ:D,Hook:U] @.made is required;
}

role Hook::Response[ENTRY]
{
    has Hash[Entryʹ:D,Hook:U] @.made is required;
}

role Hook::Response[LEDGER]
{
    has Hash[Ledgerʹ:D,Hook:U] @.made is required;
}

role Hook::Response[COA]
{
    has Hash[Coa:D,Hook:U] @.made is required;
}

role Hook::Response[HODL]
{
    has Hash[Hodl:D,Hook:U] @.made is required;
}

role Hook::Response[HOOK]
{
    has Hook:U @.made is required;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
