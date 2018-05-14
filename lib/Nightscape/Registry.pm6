use v6;
use Nightscape::Hook;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
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
    @arg (Entry::Posting:D $p, Entry::Header:D $header)
    --> Entry::Posting:D
)
{
    my Entry::Posting:D $posting =
        @hook
        .grep({ .is-match($p, $header) })
        .&send-to-hooks(@arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[POSTING] @ (Nightscape::Hook[POSTING] $hook, *@tail),
    @arg (Entry::Posting:D $p, Entry::Header:D $header)
    Bool:D :apply($)! where .so
    --> Entry::Posting:D
)
{
    my Nightscape::Hook[POSTING] @hook = |@tail;
    my Entry::Posting:D $q = $hook.apply($p, $header);
    my Entry::Posting:D $posting = send-to-hooks(@hook, [$q, $header], :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[POSTING] @,
    @ (Entry::Posting:D $p, Entry::Header:D $),
    Bool:D :apply($)! where .so
    --> Entry::Posting:D
)
{
    my Entry::Posting:D $posting = $p;
}

# --- end POSTING }}}
# --- ENTRY {{{

multi sub send-to-hooks(
    Nightscape::Hook[ENTRY] @hook,
    @arg (Entry:D $entry, Coa:D $coa, Hodl:D $hodl)
    --> Entryʹ:D
)
{
    my Entryʹ:D $entryʹ =
        @hook
        .grep({ .is-match($entry, $coa, $hodl) })
        .&send-to-hooks(@arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[ENTRY] @ (Nightscape::Hook[ENTRY] $hook, *@tail),
    @ (Entry:D $entry, Coa:D $coa, Hodl:D $hodl),
    Bool:D :apply($)! where .so
    --> Entryʹ:D
)
{
    my Nightscape::Hook[ENTRY] @hook = |@tail;
    my Entryʹ:D $eʹ = $hook.apply($entry, $coa, $hodl);
    my Entryʹ:D $entryʹ = send-to-hooks(@hook, $eʹ, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[ENTRY] @ (Nightscape::Hook[ENTRY] $hook, *@tail),
    Entryʹ:D $eʹ,
    Bool:D :apply($)! where .so
    --> Entryʹ:D
)
{
    my Nightscape::Hook[ENTRY] @hook = |@tail;
    my Entryʹ:D $fʹ = $hook.apply($eʹ);
    my Entryʹ:D $entryʹ = send-to-hooks(@hook, $fʹ, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[ENTRY] @,
    Entryʹ:D $eʹ,
    Bool:D :apply($)! where .so
    --> Entryʹ:D
)
{
    my Entryʹ:D $entryʹ = $eʹ;
}

# --- end ENTRY }}}
# --- LEDGER {{{

multi sub send-to-hooks(
    Nightscape::Hook[LEDGER] @hook,
    @arg (Ledger:D $ledger, Coa:D $coa, Hodl:D $hodl)
    --> Ledgerʹ:D
)
{
    my Ledgerʹ:D $ledgerʹ =
        @hook
        .grep({ .is-match($ledger, $coa, $hodl) })
        .&send-to-hooks(@arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[LEDGER] @ (Nightscape::Hook[LEDGER] $hook, *@tail),
    @arg (Ledger:D $ledger, Coa:D $coa, Hodl:D $hodl)
    Bool:D :apply($)! where .so
    --> Ledgerʹ:D
)
{
    my Nightscape::Hook[LEDGER] @hook = |@tail;
    my Ledgerʹ:D $lʹ = $hook.apply($ledger, $coa, $hodl);
    my Ledgerʹ:D $ledgerʹ = send-to-hooks(@hook, $lʹ, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[LEDGER] @ (Nightscape::Hook[LEDGER] $hook, *@tail),
    Ledgerʹ:D $lʹ,
    Bool:D :apply($)! where .so
    --> Ledgerʹ:D
)
{
    my Nightscape::Hook[LEDGER] @hook = |@tail;
    my Ledgerʹ:D $mʹ = $hook.apply($lʹ);
    my Ledgerʹ:D $ledgerʹ = send-to-hooks(@hook, $mʹ, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[LEDGER] @,
    Ledgerʹ:D $lʹ,
    Bool:D :apply($)! where .so
    --> Ledgerʹ:D
)
{
    my Ledgerʹ:D $ledgerʹ = $lʹ;
}

# --- end LEDGER }}}
# --- COA {{{

multi sub send-to-hooks(
    Nightscape::Hook[COA] @hook,
    @arg (Coa:D $c, Entry:D $entry, Hodl:D $hodl)
    --> Coa:D
)
{
    my Coa:D $coa =
        @hook
        .grep({ .is-match($c, $entry) })
        .&send-to-hooks(@arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[COA] @ (Nightscape::Hook[COA] $hook, *@tail),
    @arg (Coa:D $c, Entry:D $entry, Hodl:D $hodl),
    Bool:D :apply($)! where .so
    --> Coa:D
)
{
    my Nightscape::Hook[COA] @hook = |@tail;
    my Coa:D $d = $hook.apply($c, $entry, $hodl);
    my Coa:D $coa = send-to-hooks(@hook, [$d, $entry, $hodl], :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[COA] @,
    @arg (Coa:D $c, Entry:D $, Hodl:D $),
    Bool:D :apply($)! where .so
    --> Coa:D
)
{
    my Coa:D $coa = $c;
}

# --- end COA }}}
# --- HODL {{{

multi sub send-to-hooks(
    Nightscape::Hook[HODL] @hook,
    @arg (Hodl:D $h, Entry:D $entry)
    --> Hodl:D
)
{
    my Hodl:D $hodl =
        @hook
        .grep({ .is-match($h, $entry) })
        .&send-to-hooks(@arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[HODL] @ (Nightscape::Hook[HODL] $hook, *@tail),
    @arg (Hodl:D $h, Entry:D $entry)
    Bool:D :apply($)! where .so
    --> Hodl:D
)
{
    my Nightscape::Hook[HODL] @hook = |@tail;
    my Hodl:D $i = $hook.apply($h, $entry);
    my Hodl:D $hodl = send-to-hooks(@hook, [$i, $entry], :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[HODL] @,
    @arg (Hodl:D $h, Entry:D $entry),
    Bool:D :apply($)! where .so
    --> Hodl:D
)
{
    my Hodl:D $hodl = $h;
}

# --- end HODL }}}
# --- HOOK {{{

multi sub send-to-hooks(
    Nightscape::Hook[HOOK] @hook,
    @arg (Str:D $class-name, Str:D $routine-name, Capture:D $capture)
    --> Nil
)
{
    @hook
    .grep({ .is-match($class-name, $routine-name, $capture) })
    .&send-to-hooks(@arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[HOOK] @ (Nightscape::Hook[HOOK] $hook, *@tail),
    @arg (Str:D $class-name, Str:D $routine-name, Capture:D $capture),
    Bool:D :apply($)! where .so
    --> Nil
)
{
    my Nightscape::Hook[HOOK] @hook = |@tail;
    $hook.apply($class-name, $routine-name, $capture);
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
