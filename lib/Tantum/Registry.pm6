use v6;
use Tantum::Dx::Coa;
use Tantum::Dx::Entry::Posting;
use Tantum::Dx::Entry;
use Tantum::Dx::Hodl;
use Tantum::Dx::Ledger;
use Tantum::Hook::Core::Coa;
use Tantum::Hook::Core::Entry::Posting;
use Tantum::Hook::Core::Entry;
use Tantum::Hook::Core::Hodl;
use Tantum::Hook::Core::Hook;
use Tantum::Hook::Core::Ledger;
use Tantum::Hook::Response;
use Tantum::Hook;
use Tantum::Types;
use TXN::Parser::ParseTree;
unit class Registry;

has Hook:D @!hook =
    Hook::Core::Entry::Posting.new,
    Hook::Core::Entry.new,
    Hook::Core::Ledger.new,
    Hook::Core::Coa.new,
    Hook::Core::Hodl.new,
    Hook::Core::Hook.new;

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
    my Hook::Response[$type] $response = send-to-hooks($type, @hook, |c);
}

multi sub send-to-hooks(
    HookType:D $type,
    Hook[$type] @hook,
    |c
    --> Hook::Response[$type]
)
{
    my Hook[$type] $hook = @hook.first({ .is-match(|c) });
    my Hook::Response[$type] $response = send-to-hooks($type, $hook, @hook, |c);
}

multi sub send-to-hooks(
    HookType:D $type,
    Hook[$type] $hook where .defined,
    Hook[$type] @hook,
    |c
    --> Hook::Response[$type]
)
{
    my Capture:D $applied = $hook.apply(|c).Capture;
    my Hook::Response[$type] $response = send-to-hooks($type, @hook, |$applied);
}

multi sub send-to-hooks(
    HookType:D $type,
    Hook[$type] $,
    Hook[$type] @,
    |c
    --> Hook::Response[$type]
)
{
    my Hook::Response[$type] $response .= new(|c);
}

# end method send-to-hooks }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
