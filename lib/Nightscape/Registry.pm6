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
    Nightscape::Hook[POSTING] @h,
    @arg (Entry::Posting:D $, Entry::Header:D $)
    --> Entry::Postingʹ:D
)
{
    my Nightscape::Hook[POSTING] @hook = @h.grep({ .is-match(|@arg) });
    my Entry::Postingʹ:D $postingʹ = send-to-hooks(@hook, @arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[POSTING] @ (Nightscape::Hook[POSTING] $hook, *@tail),
    @arg (Entry::Posting:D $, Entry::Header:D $),
    Bool:D :apply($)! where .so,
    *%opts (
        Entry::Postingʹ:D :carry(@c)
    )
    --> Entry::Postingʹ:D
)
{
    my Nightscape::Hook[POSTING] @hook = |@tail;
    my Entry::Posting:D $pʹ = $hook.apply(|@arg, |%opts);
    my Entry::Postingʹ:D @carry = |@c, $pʹ;
    my Entry::Postingʹ:D $postingʹ =
        send-to-hooks(@hook, @arg, :apply, :@carry);
}

multi sub send-to-hooks(
    Nightscape::Hook[POSTING] @,
    @ (Entry::Posting:D $, Entry::Header:D $),
    Bool:D :apply($)! where .so,
    *% (
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
    Nightscape::Hook[ENTRY] @h,
    @arg (Entry:D $, Coa:D $, Hodl:D $)
    --> Entryʹ:D
)
{
    my Nightscape::Hook[ENTRY] @hook = @h.grep({ .is-match(|@arg) });
    my Entryʹ:D $entryʹ = send-to-hooks(@hook, @arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[ENTRY] @ (Nightscape::Hook[ENTRY] $hook, *@tail),
    @arg (Entry:D $, Coa:D $, Hodl:D $),
    Bool:D :apply($)! where .so,
    *%opts (
        Entryʹ:D :carry(@c)
    )
    --> Entryʹ:D
)
{
    my Nightscape::Hook[ENTRY] @hook = |@tail;
    my Entryʹ:D $eʹ = $hook.apply(|@arg, |%opts);
    my Entryʹ:D @carry = |@c, $eʹ;
    my Entryʹ:D $entryʹ = send-to-hooks(@hook, @arg, :apply, :@carry);
}

multi sub send-to-hooks(
    Nightscape::Hook[ENTRY] @,
    @ (Entry:D $, Coa:D $, Hodl:D $),
    Bool:D :apply($)! where .so,
    *% (
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
    Nightscape::Hook[LEDGER] @h,
    @arg (Ledger:D $, Coa:D $, Hodl:D $)
    --> Ledgerʹ:D
)
{
    my Nightscape::Hook[LEDGER] @hook = @h.grep({ .is-match(|@arg) });
    my Ledgerʹ:D $ledgerʹ = send-to-hooks(@hook, @arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[LEDGER] @ (Nightscape::Hook[LEDGER] $hook, *@tail),
    @arg (Ledger:D $, Coa:D $, Hodl:D $),
    Bool:D :apply($)! where .so,
    *%opts (
        Ledgerʹ:D :carry(@c)
    )
    --> Ledgerʹ:D
)
{
    my Nightscape::Hook[LEDGER] @hook = |@tail;
    my Ledgerʹ:D $lʹ = $hook.apply(|@arg, |%opts);
    my Ledgerʹ:D @carry = |@c, $lʹ;
    my Ledgerʹ:D $ledgerʹ = send-to-hooks(@hook, @arg, :apply, :@carry);
}

multi sub send-to-hooks(
    Nightscape::Hook[LEDGER] @,
    @ (Ledger:D $, Coa:D $, Hodl:D $),
    Bool:D :apply($)! where .so,
    *% (
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
    Nightscape::Hook[COA] @h,
    @arg (Coa:D $, Entry:D $, Hodl:D $)
    --> Coa:D
)
{
    my Nightscape::Hook[COA] @hook = @h.grep({ .is-match(|@arg) });
    my Coa:D $coa = send-to-hooks(@hook, @arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[COA] @ (Nightscape::Hook[COA] $hook, *@tail),
    @arg (Coa:D $, Entry:D $, Hodl:D $),
    Bool:D :apply($)! where .so,
    *%opts (
        Coa:D :carry(@c)
    )
    --> Coa:D
)
{
    my Nightscape::Hook[COA] @hook = |@tail;
    my Coa:D $c = $hook.apply(|@arg, |%opts);
    my Coa:D @carry = |@c, $c;
    my Coa:D $coa = send-to-hooks(@hook, @arg, :apply, :@carry);
}

multi sub send-to-hooks(
    Nightscape::Hook[COA] @,
    @arg (Coa:D $, Entry:D $, Hodl:D $),
    Bool:D :apply($)! where .so,
    *%opts (
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
    Nightscape::Hook[HODL] @h,
    @arg (Hodl:D $, Entry:D $)
    --> Hodl:D
)
{
    my Nightscape::Hook[HODL] @hook = @h.grep({ .is-match(|@arg) });
    my Hodl:D $hodl = send-to-hooks(@hook, @arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[HODL] @ (Nightscape::Hook[HODL] $hook, *@tail),
    @arg (Hodl:D $, Entry:D $),
    Bool:D :apply($)! where .so,
    *%opts (
        Hodl:D :carry(@c)
    )
    --> Hodl:D
)
{
    my Nightscape::Hook[HODL] @hook = |@tail;
    my Hodl:D $h = $hook.apply(|@arg, |%opts);
    my Hodl:D @carry = |@c, $h;
    my Hodl:D $hodl = send-to-hooks(@hook, @arg, :apply, :@carry);
}

multi sub send-to-hooks(
    Nightscape::Hook[HODL] @,
    @ (Hodl:D $, Entry:D $),
    Bool:D :apply($)! where .so,
    *% (
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
    Nightscape::Hook[HOOK] @h,
    @arg (Str:D $class-name, Str:D $routine-name, Capture:D $capture)
    --> Nil
)
{
    my Nightscape::Hook[HOOK] @hook = @h.grep({ .is-match(|@arg) });
    send-to-hooks(@hook, @arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[HOOK] @ (Nightscape::Hook[HOOK] $hook, *@tail),
    @arg (Str:D $, Str:D $, Capture:D $),
    Bool:D :apply($)! where .so
    --> Nil
)
{
    my Nightscape::Hook[HOOK] @hook = |@tail;
    $hook.apply(|@arg);
    send-to-hooks(@hook, @arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[HOOK] @,
    @ (Str:D $, Str:D $, Capture:D $),
    Bool:D :apply($)! where .so
    --> Nil
)
{*}

# --- end HOOK }}}

# end method send-to-hooks }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
