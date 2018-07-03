use v6;
use Tantum::Dx::Coa;
use Tantum::Dx::Entry::Posting;
use Tantum::Dx::Entry;
use Tantum::Dx::Hodl;
use Tantum::Dx::Ledger;
use Tantum::Hook::Coa;
use Tantum::Hook::Entry::Posting;
use Tantum::Hook::Entry;
use Tantum::Hook::Hodl;
use Tantum::Hook::Hook;
use Tantum::Hook::Ledger;
use Tantum::Hook::Response;
use Tantum::Hook;
use Tantum::Types;
use TXN::Parser::ParseTree;
use X::Tantum::Registry;
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
    HookType:D $type,
    |c
    --> Hook::Response[$type]
)
{
    # sort C<Hook>s of this C<HookType> by priority descending
    my Hook[$type] @hook =
        self.query-hooks($type).sort({ $^b.priority > $^a.priority });
    my Hook::Response[$type] $response = send-to-hooks(@hook, |c);
}

# --- POSTING {{{

multi sub send-to-hooks(
    Hook[POSTING] @hook,
    |c
    --> Hook::Response[POSTING]
)
{
    my Hook[POSTING] $hook = @hook.first({ .is-match(|c) });
    my Hook::Response[POSTING] $response = send-to-hooks($hook, @hook, |c);
}

multi sub send-to-hooks(
    Hook[POSTING] $hook where .defined,
    Hook[POSTING] @hook,
    |c
    --> Hook::Response[POSTING]
)
{
    my \applied = $hook.apply(|c);
    my Hook::Response[POSTING] $response = send-to-hooks(@hook, applied);
}

multi sub send-to-hooks(
    Hook[POSTING] $,
    Hook[POSTING] @,
    |c
    --> Hook::Response[POSTING]
)
{
    my Hook::Response[POSTING] $response .= new(|c);
}

# --- end POSTING }}}
# --- ENTRY {{{

multi sub send-to-hooks(
    Hook[ENTRY] @hook,
    |c
    --> Hook::Response[ENTRY]
)
{
    my Hook[ENTRY] $hook = @hook.first({ .is-match(|c) });
    my Hook::Response[ENTRY] $response = send-to-hooks($hook, @hook, |c);
}

multi sub send-to-hooks(
    Hook[ENTRY] $hook where .defined,
    Hook[ENTRY] @hook,
    |c
    --> Hook::Response[ENTRY]
)
{
    my \applied = $hook.apply(|c);
    my Hook::Response[ENTRY] $response = send-to-hooks(@hook, applied);
}

multi sub send-to-hooks(
    Hook[ENTRY] $,
    Hook[ENTRY] @,
    |c
    --> Hook::Response[ENTRY]
)
{
    my Hook::Response[ENTRY] $response .= new(|c);
}

# --- end ENTRY }}}
# --- LEDGER {{{

multi sub send-to-hooks(
    Hook[LEDGER] @hook,
    |c
    --> Hook::Response[LEDGER]
)
{
    my Hook[LEDGER] $hook = @hook.first({ .is-match(|c) });
    my Hook::Response[LEDGER] $response = send-to-hooks($hook, @hook, |c);
}

multi sub send-to-hooks(
    Hook[LEDGER] $hook where .defined,
    Hook[LEDGER] @hook,
    |c
    --> Hook::Response[LEDGER]
)
{
    my \applied = $hook.apply(|c);
    my Hook::Response[LEDGER] $response = send-to-hooks(@hook, applied);
}

multi sub send-to-hooks(
    Hook[LEDGER] $,
    Hook[LEDGER] @,
    |c
    --> Hook::Response[LEDGER]
)
{
    my Hook::Response[LEDGER] $response .= new(|c);
}

# --- end LEDGER }}}
# --- COA {{{

multi sub send-to-hooks(
    Hook[COA] @hook,
    |c
    --> Hook::Response[COA]
)
{
    my Hook[COA] $hook = @hook.first({ .is-match(|c) });
    my Hook::Response[COA] $response = send-to-hooks($hook, @hook, |c);
}

multi sub send-to-hooks(
    Hook[COA] $hook where .defined,
    Hook[COA] @hook,
    |c
    --> Hook::Response[COA]
)
{
    my \applied = $hook.apply(|%opts, |c);
    my Hook::Response[COA] $response = send-to-hooks(@hook, applied);
}

multi sub send-to-hooks(
    Hook[COA] $,
    Hook[COA] @,
    |c
    --> Hook::Response[COA]
)
{
    my Hook::Response[COA] $response .= new(|c);
}

# --- end COA }}}
# --- HODL {{{

multi sub send-to-hooks(
    Hook[HODL] @hook,
    |c
    --> Hook::Response[HODL]
)
{
    my Hook[HODL] $hook = @hook.first({ .is-match(|c) });
    my Hook::Response[HODL] $response = send-to-hooks($hook, @hook, |c);
}

multi sub send-to-hooks(
    Hook[HODL] $hook where .defined,
    Hook[HODL] @hook,
    |c
    --> Hook::Response[HODL]
)
{
    my \applied = $hook.apply(|%opts, |c);
    my Hook::Response[HODL] $response = send-to-hooks(@hook, applied);
}

multi sub send-to-hooks(
    Hook[HODL] $,
    Hook[HODL] @,
    |c
    --> Hook::Response[HODL]
)
{
    my Hook::Response[HODL] $response .= new(|c);
}

# --- end HODL }}}
# --- HOOK {{{

multi sub send-to-hooks(
    Hook[HOOK] @hook,
    |c
    --> Hook::Response[HOOK]
)
{
    my Hook[HOOK] $hook = @hook.first({ .is-match(|c) });
    my Hook::Response[HOOK] $response = send-to-hooks($hook, @hook, |c);
}

multi sub send-to-hooks(
    Hook[HOOK] $hook where .defined,
    Hook[HOOK] @hook,
    |c
    --> Hook::Response[HOOK]
)
{
    my \applied = $hook.apply(|c);
    my Hook::Response[HOOK] $response = send-to-hooks(@hook, applied);
}

multi sub send-to-hooks(
    Hook[HOOK] $,
    Hook[HOOK] @,
    |c
    --> Hook::Response[HOOK]
)
{
    my Hook::Response[HOOK] $response .= new(|c);
}

# --- end HOOK }}}

# end method send-to-hooks }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
