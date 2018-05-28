use v6;
use Nightscape::Dx;
use Nightscape::Hook;
use Nightscape::Hook::Entry::Posting;
use Nightscape::Hook::Entry;
use Nightscape::Hook::Ledger;
use Nightscape::Hook::Coa;
use Nightscape::Hook::Hodl;
use Nightscape::Hook::Hook;
use Nightscape::Types;
use TXN::Parser::ParseTree;
unit class Nightscape::Registry;

has Nightscape::Hook:D @!hook =
    Nightscape::Hook::Entry::Posting.new,
    Nightscape::Hook::Entry.new,
    Nightscape::Hook::Ledger.new,
    Nightscape::Hook::Coa.new,
    Nightscape::Hook::Hodl.new,
    Nightscape::Hook::Hook.new;

# method hook {{{

method hook(::?CLASS:D: --> Array[Nightscape::Hook:D])
{
    my Nightscape::Hook:D @hook = @!hook;
}

# end method hook }}}
# method register {{{

method register(Nightscape::Hook:D $hook --> Nil)
{
    push(@!hook, $hook);
}

# end method register }}}
# method unregister {{{

# tbd
method unregister(Nightscape::Hook:D $hook --> Nil)
{*}

# end method unregister }}}
# method query-hooks {{{

# query hooks by type
method query-hooks(
    ::?CLASS:D:
    HookType $type
    --> Array[Nightscape::Hook[$type]]
)
{
    my Nightscape::Hook[$type] @hook = @.hook.grep(Nightscape::Hook[$type]);
}

# end method query-hooks }}}
# method send-to-hooks {{{

method send-to-hooks(
    ::?CLASS:D:
    HookType $type,
    @arg
)
{
    # sort C<Nightscape::Hook>s of this C<HookType> by priority descending
    my Nightscape::Hook[$type] @hook =
        self.query-hooks($type).sort({ $^b.priority > $^a.priority });
    send-to-hooks(@hook, @arg);
}

# --- POSTING {{{

multi sub send-to-hooks(
    Nightscape::Hook[POSTING] @hook,
    @arg (Entry::Posting:D $, Entry::Header:D $),
    *%opts (
        Nightscape::Hook:U :applied(@),
        Entry::Postingʹ:D :carry(@)
    )
    --> Entry::Postingʹ:D
)
{
    my Nightscape::Hook[POSTING] $hook =
        @hook.first({ .is-match(|@arg, |%opts) });
    my Entry::Postingʹ:D $postingʹ = send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Nightscape::Hook[POSTING] $hook where .defined,
    Nightscape::Hook[POSTING] @hook,
    @arg (Entry::Posting:D $, Entry::Header:D $),
    *%opts (
        Nightscape::Hook:U :applied(@a),
        Entry::Postingʹ:D :carry(@c)
    )
    --> Entry::Postingʹ:D
)
{
    my Entry::Posting:D $pʹ = $hook.apply(|@arg, |%opts);
    my Nightscape::Hook:U @applied = |@a, $hook.WHAT;
    my Entry::Postingʹ:D @carry = |@c, $pʹ;
    my Entry::Postingʹ:D $postingʹ =
        send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Nightscape::Hook[POSTING] $,
    Nightscape::Hook[POSTING] @,
    @ (Entry::Posting:D $, Entry::Header:D $),
    *% (
        Nightscape::Hook:U :applied(@),
        Entry::Postingʹ:D :@carry! where .so
    )
    --> Entry::Postingʹ:D
)
{
    my Entry::Postingʹ:D $postingʹ = @carry.tail;
}

# --- end POSTING }}}
# --- ENTRY {{{

multi sub send-to-hooks(
    Nightscape::Hook[ENTRY] @hook,
    @arg (Entry:D $, Coa:D $, Hodl:D $),
    *%opts (
        Nightscape::Hook:U :applied(@),
        Entryʹ:D :carry(@c)
    )
    --> Entryʹ:D
)
{
    my Nightscape::Hook[ENTRY] $hook =
        @hook.first({ .is-match(|@arg, |%opts) });
    my Entryʹ:D $entryʹ = send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Nightscape::Hook[ENTRY] $hook where .defined,
    Nightscape::Hook[ENTRY] @hook,
    @arg (Entry:D $, Coa:D $, Hodl:D $),
    *%opts (
        Nightscape::Hook:U :applied(@a),
        Entryʹ:D :carry(@c)
    )
    --> Entryʹ:D
)
{
    my Entryʹ:D $eʹ = $hook.apply(|@arg, |%opts);
    my Nightscape::Hook:U @applied = |@a, $hook.WHAT;
    my Entryʹ:D @carry = |@c, $eʹ;
    my Entryʹ:D $entryʹ = send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Nightscape::Hook[ENTRY] $,
    Nightscape::Hook[ENTRY] @,
    @ (Entry:D $, Coa:D $, Hodl:D $),
    *% (
        Nightscape::Hook:U :applied(@),
        Entryʹ:D :@carry! where .so
    )
    --> Entryʹ:D
)
{
    my Entryʹ:D $entryʹ = @carry.tail;
}

# --- end ENTRY }}}
# --- LEDGER {{{

multi sub send-to-hooks(
    Nightscape::Hook[LEDGER] @hook,
    @arg (Ledger:D $, Coa:D $, Hodl:D $),
    *%opts (
        Nightscape::Hook:U :applied(@),
        Ledgerʹ:D :carry(@)
    )
    --> Ledgerʹ:D
)
{
    my Nightscape::Hook[LEDGER] $hook =
        @hook.first({ .is-match(|@arg, |%opts) });
    my Ledgerʹ:D $ledgerʹ = send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Nightscape::Hook[LEDGER] $hook where .defined,
    Nightscape::Hook[LEDGER] @hook,
    @arg (Ledger:D $, Coa:D $, Hodl:D $),
    *%opts (
        Nightscape::Hook:U :applied(@a),
        Ledgerʹ:D :carry(@c)
    )
    --> Ledgerʹ:D
)
{
    my Ledgerʹ:D $lʹ = $hook.apply(|@arg, |%opts);
    my Nightscape::Hook:U @applied = |@a, $hook.WHAT;
    my Ledgerʹ:D @carry = |@c, $lʹ;
    my Ledgerʹ:D $ledgerʹ = send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Nightscape::Hook[LEDGER] $,
    Nightscape::Hook[LEDGER] @,
    @ (Ledger:D $, Coa:D $, Hodl:D $),
    *% (
        Nightscape::Hook:U :applied(@),
        Ledgerʹ:D :@carry! where .so
    )
    --> Ledgerʹ:D
)
{
    my Ledgerʹ:D $ledgerʹ = @carry.tail;
}

# --- end LEDGER }}}
# --- COA {{{

multi sub send-to-hooks(
    Nightscape::Hook[COA] @hook,
    @arg (Coa:D $, Entry:D $, Hodl:D $)
    *%opts (
        Nightscape::Hook:U :applied(@),
        Coa:D :carry(@)
    )
    --> Coa:D
)
{
    my Nightscape::Hook[COA] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my Coa:D $coa = send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Nightscape::Hook[COA] $hook where .defined,
    Nightscape::Hook[COA] @hook,
    @arg (Coa:D $, Entry:D $, Hodl:D $),
    *%opts (
        Nightscape::Hook:U :applied(@a),
        Coa:D :carry(@c)
    )
    --> Coa:D
)
{
    my Coa:D $c = $hook.apply(|@arg, |%opts);
    my Nightscape::Hook:U @applied = |@a, $hook.WHAT;
    my Coa:D @carry = |@c, $c;
    my Coa:D $coa = send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Nightscape::Hook[COA] $,
    Nightscape::Hook[COA] @,
    @ (Coa:D $, Entry:D $, Hodl:D $),
    *% (
        Nightscape::Hook:U :applied(@),
        Coa:D :@carry! where .so
    )
    --> Coa:D
)
{
    my Coa:D $coa = @carry.tail;
}

# --- end COA }}}
# --- HODL {{{

multi sub send-to-hooks(
    Nightscape::Hook[HODL] @hook,
    @arg (Hodl:D $, Entry:D $)
    *%opts (
        Nightscape::Hook:U :applied(@),
        Hodl:D :carry(@)
    )
    --> Hodl:D
)
{
    my Nightscape::Hook[HODL] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    my Hodl:D $hodl = send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Nightscape::Hook[HODL] $hook where .defined,
    Nightscape::Hook[HODL] @hook,
    @arg (Hodl:D $, Entry:D $),
    *%opts (
        Nightscape::Hook:U :applied(@a),
        Hodl:D :carry(@c)
    )
    --> Hodl:D
)
{
    my Hodl:D $h = $hook.apply(|@arg, |%opts);
    my Nightscape::Hook:U @applied = |@a, $hook.WHAT;
    my Hodl:D @carry = |@c, $h;
    my Hodl:D $hodl = send-to-hooks(@hook, @arg, :@applied, :@carry);
}

multi sub send-to-hooks(
    Nightscape::Hook[HODL] $,
    Nightscape::Hook[HODL] @,
    @ (Hodl:D $, Entry:D $),
    *% (
        Nightscape::Hook:U :applied(@),
        Hodl:D :@carry! where .so
    )
    --> Hodl:D
)
{
    my Hodl:D $hodl = @carry.tail;
}

# --- end HODL }}}
# --- HOOK {{{

multi sub send-to-hooks(
    Nightscape::Hook[HOOK] @hook,
    @arg (
        Str:D $enter-leave,
        Str:D $class-name,
        Str:D $routine-name,
        Capture:D $capture
    ),
    *%opts (
        Nightscape::Hook:U :applied(@)
    )
    --> Nil
)
{
    my Nightscape::Hook[HOOK] $hook = @hook.first({ .is-match(|@arg, |%opts) });
    send-to-hooks($hook, @hook, @arg, |%opts);
}

multi sub send-to-hooks(
    Nightscape::Hook[HOOK] $hook where .defined,
    Nightscape::Hook[HOOK] @hook,
    @arg (
        Str:D $,
        Str:D $,
        Str:D $,
        Capture:D $
    ),
    *%opts (
        Nightscape::Hook:U :applied(@a)
    )
    --> Nil
)
{
    $hook.apply(|@arg, |%opts);
    my Nightscape::Hook:U @applied = |@a, $hook.WHAT;
    send-to-hooks(@hook, @arg, :@applied);
}

multi sub send-to-hooks(
    Nightscape::Hook[HOOK] $,
    Nightscape::Hook[HOOK] @,
    @ (
        Str:D $,
        Str:D $,
        Str:D $,
        Capture:D $
    ),
    *%opts (
        Nightscape::Hook:U :applied(@)
    )
    --> Nil
)
{*}

# --- end HOOK }}}

# end method send-to-hooks }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
