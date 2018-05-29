use v6;
use Nightscape::Dx;
use Nightscape::Hook;
use Nightscape::Hook::Entry::Posting;
use Nightscape::Hook::Entry;
use Nightscape::Hook::Ledger;
use Nightscape::Hook::Coa;
use Nightscape::Hook::Hodl;
use Nightscape::Hook::Hook;
use Nightscape::Registry::Payload;
use Nightscape::Types;
use TXN::Parser::ParseTree;
unit class Nightscape::Registry;

has Hook:D @!hook =
    Hook::Entry::Posting.new,
    Hook::Entry.new,
    Hook::Ledger.new,
    Hook::Coa.new,
    Hook::Hodl.new,
    Hook::Hook.new;

# method hook {{{

method hook(::?CLASS:D: --> Array[Hook:D])
{
    my Hook:D @hook = @!hook;
}

# end method hook }}}
# method register {{{

method register(Hook:D $hook --> Nil)
{
    push(@!hook, $hook);
}

# end method register }}}
# method unregister {{{

# tbd
method unregister(Hook:D $hook --> Nil)
{*}

# end method unregister }}}
# method query-hooks {{{

# query hooks by type
method query-hooks(::?CLASS:D: HookType $type --> Array[Hook[$type]])
{
    my Hook[$type] @hook = @.hook.grep(Hook[$type]);
}

# end method query-hooks }}}
# method send-to-hooks {{{

method send-to-hooks(
    ::?CLASS:D:
    HookType $type,
    @arg
    --> Nightscape::Registry::Payload:D
)
{
    # sort C<Hook>s of this C<HookType> by priority descending
    my Hook[$type] @hook =
        self.query-hooks($type).sort({ $^b.priority > $^a.priority });
    my Nightscape::Registry::Payload[$type] $payload =
        send-to-hooks(@hook, @arg);
}

# --- POSTING {{{

multi sub send-to-hooks(
    Hook[POSTING] @hook,
    @arg (Entry::Posting:D $, Entry::Header:D $),
    *%opts (
        Hook:U :applied(@),
        Entry::Postingʹ:D :carry(@)
    )
    --> Nightscape::Registry::Payload[POSTING]
)
{
    my Hook[POSTING] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my Nightscape::Registry::Payload[POSTING] $payload =
        send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[POSTING] $hook where .defined,
    Hook[POSTING] @hook,
    @arg (Entry::Posting:D $, Entry::Header:D $),
    *%opts (
        Hook:U :applied(@a),
        Entry::Postingʹ:D :carry(@c)
    )
    --> Nightscape::Registry::Payload[POSTING]
)
{
    my Entry::Posting:D $pʹ = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Entry::Postingʹ:D @carry = |@c, $pʹ;
    my Nightscape::Registry::Payload[POSTING] $payload =
        send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Hook[POSTING] $,
    Hook[POSTING] @,
    @ (Entry::Posting:D $, Entry::Header:D $),
    *% (
        Hook:U :@applied! where .so,
        Entry::Postingʹ:D :@carry! where .so
    )
    --> Nightscape::Registry::Payload[POSTING]
)
{
    my Hash[Entry::Postingʹ:D,Hook:U] @made = @applied Z=> @carry;
    my Nightscape::Registry::Payload[POSTING] $payload .= new(:@made);
}

# --- end POSTING }}}
# --- ENTRY {{{

multi sub send-to-hooks(
    Hook[ENTRY] @hook,
    @arg (Entry:D $, Coa:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@),
        Entryʹ:D :carry(@c)
    )
    --> Nightscape::Registry::Payload[ENTRY]
)
{
    my Hook[ENTRY] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my Nightscape::Registry::Payload[ENTRY] $payload =
        send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[ENTRY] $hook where .defined,
    Hook[ENTRY] @hook,
    @arg (Entry:D $, Coa:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@a),
        Entryʹ:D :carry(@c)
    )
    --> Nightscape::Registry::Payload[ENTRY]
)
{
    my Entryʹ:D $eʹ = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Entryʹ:D @carry = |@c, $eʹ;
    my Nightscape::Registry::Payload[ENTRY] $payload =
        send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Hook[ENTRY] $,
    Hook[ENTRY] @,
    @ (Entry:D $, Coa:D $, Hodl:D $),
    *% (
        Hook:U :@applied! where .so,
        Entryʹ:D :@carry! where .so
    )
    --> Nightscape::Registry::Payload[ENTRY]
)
{
    my Hash[Entryʹ:D,Hook:U] @made = @applied Z=> @carry;
    my Nightscape::Registry::Payload[ENTRY] $payload .= new(:@made);
}

# --- end ENTRY }}}
# --- LEDGER {{{

multi sub send-to-hooks(
    Hook[LEDGER] @hook,
    @arg (Ledger:D $, Coa:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@),
        Ledgerʹ:D :carry(@)
    )
    --> Nightscape::Registry::Payload[LEDGER]
)
{
    my Hook[LEDGER] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my Nightscape::Registry::Payload[LEDGER] $payload =
        send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[LEDGER] $hook where .defined,
    Hook[LEDGER] @hook,
    @arg (Ledger:D $, Coa:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@a),
        Ledgerʹ:D :carry(@c)
    )
    --> Nightscape::Registry::Payload[LEDGER]
)
{
    my Ledgerʹ:D $lʹ = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Ledgerʹ:D @carry = |@c, $lʹ;
    my Nightscape::Registry::Payload[LEDGER] $payload =
        send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Hook[LEDGER] $,
    Hook[LEDGER] @,
    @ (Ledger:D $, Coa:D $, Hodl:D $),
    *% (
        Hook:U :@applied! where .so,
        Ledgerʹ:D :@carry! where .so
    )
    --> Nightscape::Registry::Payload[LEDGER]
)
{
    my Hash[Ledgerʹ:D,Hook:U] @made = @applied Z=> @carry;
    my Nightscape::Registry::Payload[LEDGER] $payload .= new(:@made);
}

# --- end LEDGER }}}
# --- COA {{{

multi sub send-to-hooks(
    Hook[COA] @hook,
    @arg (Coa:D $, Entry:D $, Hodl:D $)
    *%opts (
        Hook:U :applied(@),
        Coa:D :carry(@)
    )
    --> Nightscape::Registry::Payload[COA]
)
{
    my Hook[COA] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my Nightscape::Registry::Payload[COA] $payload =
        send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[COA] $hook where .defined,
    Hook[COA] @hook,
    @arg (Coa:D $, Entry:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@a),
        Coa:D :carry(@c)
    )
    --> Nightscape::Registry::Payload[COA]
)
{
    my Coa:D $c = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Coa:D @carry = |@c, $c;
    my Nightscape::Registry::Payload[COA] $payload =
        send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Hook[COA] $,
    Hook[COA] @,
    @ (Coa:D $, Entry:D $, Hodl:D $),
    *% (
        Hook:U :applied(@),
        Coa:D :@carry! where .so
    )
    --> Nightscape::Registry::Payload[COA]
)
{
    my Hash[Coa:D,Hook:U] @made = @applied Z=> @carry;
    my Nightscape::Registry::Payload[COA] $payload .= new(:@made);
}

# --- end COA }}}
# --- HODL {{{

multi sub send-to-hooks(
    Hook[HODL] @hook,
    @arg (Hodl:D $, Entry:D $)
    *%opts (
        Hook:U :applied(@),
        Hodl:D :carry(@)
    )
    --> Nightscape::Registry::Payload[HODL]
)
{
    my Hook[HODL] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my Nightscape::Registry::Payload[HODL] $payload =
        send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[HODL] $hook where .defined,
    Hook[HODL] @hook,
    @arg (Hodl:D $, Entry:D $),
    *%opts (
        Hook:U :applied(@a),
        Hodl:D :carry(@c)
    )
    --> Nightscape::Registry::Payload[HODL]
)
{
    my Hodl:D $h = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Hodl:D @carry = |@c, $h;
    my Nightscape::Registry::Payload[HODL] $payload =
        send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Hook[HODL] $,
    Hook[HODL] @,
    @ (Hodl:D $, Entry:D $),
    *% (
        Hook:U :@applied! where .so,
        Hodl:D :@carry! where .so
    )
    --> Nightscape::Registry::Payload[HODL]
)
{
    my Hash[Hodl:D,Hook:U] @made = @applied Z=> @carry;
    my Nightscape::Registry::Payload[HODL] $payload .= new(:@made);
}

# --- end HODL }}}
# --- HOOK {{{

multi sub send-to-hooks(
    Hook[HOOK] @hook,
    @arg (
        Str:D $enter-leave,
        Str:D $class-name,
        Str:D $routine-name,
        Capture:D $capture
    ),
    *%opts (
        Hook:U :applied(@)
    )
    --> Nightscape::Registry::Payload[HOOK]
)
{
    my Hook[HOOK] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my Nightscape::Registry::Payload[HOOK] $payload =
        send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[HOOK] $hook where .defined,
    Hook[HOOK] @hook,
    @arg (
        Str:D $,
        Str:D $,
        Str:D $,
        Capture:D $
    ),
    *%opts (
        Hook:U :applied(@a)
    )
    --> Nightscape::Registry::Payload[HOOK]
)
{
    $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Nightscape::Registry::Payload[HOOK] $payload =
        send-to-hooks(@hook, @arg, :@applied);
}

multi sub send-to-hooks(
    Hook[HOOK] $,
    Hook[HOOK] @,
    @ (
        Str:D $,
        Str:D $,
        Str:D $,
        Capture:D $
    ),
    *%opts (
        Hook:U :@applied! where .so
    )
    --> Nightscape::Registry::Payload[HOOK]
)
{
    my Hook:U @made = @applied;
    my Nightscape::Registry::Payload[HOOK] $payload .= new(:@made);
}

# --- end HOOK }}}

# end method send-to-hooks }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
