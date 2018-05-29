use v6;
use Nightscape::Dx::Account;
use Nightscape::Dx::Coa;
use Nightscape::Dx::Entry;
use Nightscape::Dx::Entry::Posting;
use Nightscape::Dx::Hodl;
use Nightscape::Dx::Hodling;
use Nightscape::Dx::Ledger;
use Nightscape::Hook;
use Nightscape::Types;

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
