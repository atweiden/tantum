use v6;
use Nightscape::Hook;
use Nightscape::Types;
use TXN::Parser::Types;
unit class Nightscape::Registry;

has Nightscape::Hook:D @!hook;

method hook(::?CLASS:D: --> Array[Nightscape::Hook:D])
{
    my Nightscape::Hook:D @hook = @!hook;
}

method register(Nightscape::Hook:D $hook --> Nil)
{
    push(@!hook, $hook);
}

# tbd
method unregister(Nightscape::Hook:D $hook --> Nil)
{*}

# query hooks by type
method query-hooks(
    ::?CLASS:D:
    HookType $type
    --> Array[Nightscape::Hook[$type]]
)
{
    my Nightscape::Hook[$type] @hook = @.hook.grep(Nightscape::Hook[$type]);
}

# method send-to-hooks {{{

method send-to-hooks(
    ::?CLASS:D:
    HookType $type,
    @arg
)
{
    # find C<Nightscape::Hook>s of this C<HookType>
    my Nightscape::Hook[$type] @hook = self.query-hooks($type);
    send-to-hooks(@hook, @arg);
}

# --- POSTING {{{

multi sub send-to-hooks(
    Nightscape::Hook[POSTING] @hook,
    @arg (Entry::Posting:D $posting, Coa:D $c, Hodl:D $hodl)
    --> Entry::Postingʹ:D
)
{
    my Entry::Postingʹ:D $postingʹ =
        @hook
        .grep({ .is-match($c, $posting) })
        .sort({ $^b.priority > $^a.priority })
        .&send-to-hooks(@arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[POSTING] @ (Nightscape::Hook[POSTING] $hook, *@tail),
    @arg (Entry::Posting:D $p, Coa:D $c, Hodl:D $h),
    Bool:D :apply($)! where .so
    --> Entry::Postingʹ:D
)
{
    my Nightscape::Hook[POSTING] @hook = |@tail;
    my Entry::Postingʹ:D $qʹ = $hook.apply($p, $c, $h);
    my Entry::Posting $posting = $qʹ.posting;
    my Coa:D $coa = $qʹ.coa;
    my Hodl:D $hodl = $qʹ.hodl;
    my Entry::Postingʹ:D $postingʹ =
        send-to-hooks(@hook, [$posting, $coa, $hodl], :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[POSTING] @,
    @arg (Entry::Posting:D $posting, Coa:D $coa, Hodl:D $hodl),
    Bool:D :apply($)! where .so
    --> Entry::Postingʹ:D
)
{
    my Entry::Postingʹ $postingʹ .= new(:$posting, :$coa, :$hodl);
}

# --- end POSTING }}}
# --- COA {{{

multi sub send-to-hooks(
    Nightscape::Hook[COA] @hook,
    @arg (Coa:D $c, Entry::Posting:D $posting)
    --> Coa:D
)
{
    my COA:D $coa =
        @hook
        # grep C<Nightscape::Hook>s for matches
        .grep({ .is-match($c, $posting) })
        # sort C<Nightscape::Hook>s by priority descending
        .sort({ $^b.priority > $^a.priority })
        # apply C<Nightscape::Hook>s
        .&send-to-hooks(@arg, :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[COA] @ (Nightscape::Hook[COA] $hook, *@tail),
    @arg (Coa:D $c, Entry::Posting:D $posting),
    Bool:D :apply($)! where .so
    --> Coa:D
)
{
    my Nightscape::Hook[COA] @hook = |@tail;
    my Coa:D $d = $hook.apply($c, $posting);
    my Coa:D $coa = send-to-hooks(@hook, [$d, $posting], :apply);
}

multi sub send-to-hooks(
    Nightscape::Hook[COA] @,
    @arg (Coa:D $c, Entry::Posting:D $),
    Bool:D :apply($)! where .so
    --> Coa:D
)
{
    my Coa:D $coa = $c;
}

# --- end COA }}}

# end method send-to-hooks }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
