use v6;
use Nightscape::Dx::Coa;
use Nightscape::Dx::Entry::Posting;
use Nightscape::Dx::Entry;
use Nightscape::Dx::Hodl;
use Nightscape::Dx::Ledger;
use Nightscape::Hook::Coa;
use Nightscape::Hook::Entry::Posting;
use Nightscape::Hook::Entry;
use Nightscape::Hook::Hodl;
use Nightscape::Hook::Hook;
use Nightscape::Hook::Ledger;
use Nightscape::Hook;
use Nightscape::HookRes;
use Nightscape::Types;
use TXN::Parser::ParseTree;
unit class Registry;

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
    --> HookRes[$type]
)
{
    # sort C<Hook>s of this C<HookType> by priority descending
    my Hook[$type] @hook =
        self.query-hooks($type).sort({ $^b.priority > $^a.priority });
    my HookRes[$type] $payload = send-to-hooks(@hook, @arg);
}

# --- POSTING {{{

multi sub send-to-hooks(
    Hook[POSTING] @hook,
    @arg (Entry::Posting:D $, Entry::Header:D $),
    *%opts (
        Hook:U :applied(@),
        Entry::Postingʹ:D :carry(@)
    )
    --> HookRes[POSTING]
)
{
    my Hook[POSTING] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my HookRes[POSTING] $payload = send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[POSTING] $hook where .defined,
    Hook[POSTING] @hook,
    @arg (Entry::Posting:D $, Entry::Header:D $),
    *%opts (
        Hook:U :applied(@a),
        Entry::Postingʹ:D :carry(@c)
    )
    --> HookRes[POSTING]
)
{
    my Entry::Posting:D $postingʹ = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Entry::Postingʹ:D @carry = |@c, $postingʹ;
    my HookRes[POSTING] $payload =
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
    --> HookRes[POSTING]
)
{
    my Hash[Entry::Postingʹ:D,Hook:U] @made = @applied Z=> @carry;
    my HookRes[POSTING] $payload .= new(:@made);
}

# --- end POSTING }}}
# --- ENTRY {{{

multi sub send-to-hooks(
    Hook[ENTRY] @hook,
    @arg (Entry:D $, Coa:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@),
        Entryʹ:D :carry(@)
    )
    --> HookRes[ENTRY]
)
{
    my Hook[ENTRY] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my HookRes[ENTRY] $payload = send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[ENTRY] $hook where .defined,
    Hook[ENTRY] @hook,
    @arg (Entry:D $, Coa:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@a),
        Entryʹ:D :carry(@c)
    )
    --> HookRes[ENTRY]
)
{
    my Entryʹ:D $entryʹ = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Entryʹ:D @carry = |@c, $entryʹ;
    my HookRes[ENTRY] $payload = send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Hook[ENTRY] $,
    Hook[ENTRY] @,
    @ (Entry:D $, Coa:D $, Hodl:D $),
    *% (
        Hook:U :@applied! where .so,
        Entryʹ:D :@carry! where .so
    )
    --> HookRes[ENTRY]
)
{
    my Hash[Entryʹ:D,Hook:U] @made = @applied Z=> @carry;
    my HookRes[ENTRY] $payload .= new(:@made);
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
    --> HookRes[LEDGER]
)
{
    my Hook[LEDGER] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my HookRes[LEDGER] $payload = send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[LEDGER] $hook where .defined,
    Hook[LEDGER] @hook,
    @arg (Ledger:D $, Coa:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@a),
        Ledgerʹ:D :carry(@c)
    )
    --> HookRes[LEDGER]
)
{
    my Ledgerʹ:D $ledgerʹ = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Ledgerʹ:D @carry = |@c, $ledgerʹ;
    my HookRes[LEDGER] $payload =
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
    --> HookRes[LEDGER]
)
{
    my Hash[Ledgerʹ:D,Hook:U] @made = @applied Z=> @carry;
    my HookRes[LEDGER] $payload .= new(:@made);
}

# --- end LEDGER }}}
# --- COA {{{

multi sub send-to-hooks(
    Hook[COA] @hook,
    @arg (Coa:D $, Entry:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@),
        Coa:D :carry(@)
    )
    --> HookRes[COA]
)
{
    my Hook[COA] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my HookRes[COA] $payload = send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[COA] $hook where .defined,
    Hook[COA] @hook,
    @arg (Coa:D $, Entry:D $, Hodl:D $),
    *%opts (
        Hook:U :applied(@a),
        Coa:D :carry(@c)
    )
    --> HookRes[COA]
)
{
    my Coa:D $coa = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Coa:D @carry = |@c, $coa;
    my HookRes[COA] $payload = send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Hook[COA] $,
    Hook[COA] @,
    @ (Coa:D $, Entry:D $, Hodl:D $),
    *% (
        Hook:U :@applied! where .so,
        Coa:D :@carry! where .so
    )
    --> HookRes[COA]
)
{
    my Hash[Coa:D,Hook:U] @made = @applied Z=> @carry;
    my HookRes[COA] $payload .= new(:@made);
}

# --- end COA }}}
# --- HODL {{{

multi sub send-to-hooks(
    Hook[HODL] @hook,
    @arg (Hodl:D $, Entry:D $),
    *%opts (
        Hook:U :applied(@),
        Hodl:D :carry(@)
    )
    --> HookRes[HODL]
)
{
    my Hook[HODL] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my HookRes[HODL] $payload = send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Hook[HODL] $hook where .defined,
    Hook[HODL] @hook,
    @arg (Hodl:D $, Entry:D $),
    *%opts (
        Hook:U :applied(@a),
        Hodl:D :carry(@c)
    )
    --> HookRes[HODL]
)
{
    my Hodl:D $hodl = $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my Hodl:D @carry = |@c, $hodl;
    my HookRes[HODL] $payload = send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Hook[HODL] $,
    Hook[HODL] @,
    @ (Hodl:D $, Entry:D $),
    *% (
        Hook:U :@applied! where .so,
        Hodl:D :@carry! where .so
    )
    --> HookRes[HODL]
)
{
    my Hash[Hodl:D,Hook:U] @made = @applied Z=> @carry;
    my HookRes[HODL] $payload .= new(:@made);
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
    --> HookRes[HOOK]
)
{
    my Hook[HOOK] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my HookRes[HOOK] $payload = send-to-hooks($hook, @hook, @arg, |%opts);
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
    --> HookRes[HOOK]
)
{
    $hook.apply(|@arg, |%opts);
    my Hook:U @applied = |@a, $hook.WHAT;
    my HookRes[HOOK] $payload = send-to-hooks(@hook, @arg, :@applied);
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
    --> HookRes[HOOK]
)
{
    my Hook:U @made = @applied;
    my HookRes[HOOK] $payload .= new(:@made);
}

# --- end HOOK }}}

# end method send-to-hooks }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
