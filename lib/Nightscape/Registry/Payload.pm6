use v6;
use Nightscape::Dx;
use Nightscape::Hook;
use Nightscape::Types;

role Nightscape::Registry::Payload[POSTING]
{
    has Hash[Entry::Postingʹ:D,Hook:U] @.made is required;
}

role Nightscape::Registry::Payload[ENTRY]
{
    has Hash[Entryʹ:D,Hook:U] @.made is required;
}

role Nightscape::Registry::Payload[LEDGER]
{
    has Hash[Ledgerʹ:D,Hook:U] @.made is required;
}

role Nightscape::Registry::Payload[COA]
{
    has Hash[Coa:D,Hook:U] @.made is required;
}

role Nightscape::Registry::Payload[HODL]
{
    has Hash[Hodl:D,Hook:U] @.made is required;
}

role Nightscape::Registry::Payload[HOOK]
{
    has Hook:U @.made is required;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
