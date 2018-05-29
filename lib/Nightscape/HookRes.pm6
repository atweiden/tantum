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

role HookResponse[POSTING]
{
    has Hash[Entry::Postingʹ:D,Hook:U] @.made is required;
}

role HookResponse[ENTRY]
{
    has Hash[Entryʹ:D,Hook:U] @.made is required;
}

role HookResponse[LEDGER]
{
    has Hash[Ledgerʹ:D,Hook:U] @.made is required;
}

role HookResponse[COA]
{
    has Hash[Coa:D,Hook:U] @.made is required;
}

role HookResponse[HODL]
{
    has Hash[Hodl:D,Hook:U] @.made is required;
}

role HookResponse[HOOK]
{
    has Hook:U @.made is required;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
