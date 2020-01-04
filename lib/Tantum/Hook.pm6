use v6;
use Tantum::Hook::Action;
use Tantum::Hook::Trigger;
use Tantum::Types;

# p6doc {{{

=begin pod
=head NAME

Hook

=head DESCRIPTION

=begin paragraph
Hooks are the primary means by which Tantum produces essential accounting
reports. Through hooks, Tantum can take a list of C<Entry>s parsed from
a plain-text TXN document and convert it into usable data, e.g. a I<Chart
of Accounts>.

Hooks allow for closely examining and logging each and every step a TXN
document goes through along the way to an essential report, leading to
increased auditability.

All hooks must provide a C<method apply> and a C<method is-match>.
=end paragraph

=head2 Hooks By Category

=head3 Category: Primitive

=begin paragraph
Category I<Primitive> contains hooks designed to operate on TXN primitives
C<Entry::Posting>, C<Entry> and C<Ledger>.
=end paragraph

=begin item
B<Posting>

I<Posting> hooks are scoped to C<Entry::Posting>s. Each time a new
C<Entry::Posting> is queued for handling, I<Posting> hooks will be
filtered for relevancy and the actions inscribed in matching hooks
executed.
=end item

=begin item
B<Entry>

I<Entry> hooks are scoped to C<Entry>s. Each time a new C<Entry> is
queued for handling, I<Entry> hooks will be filtered for relevancy and
the actions inscribed in matching hooks executed.
=end item

=begin item
B<Ledger>

I<Ledger> hooks are scoped to C<Ledger>s. Each time a new C<Ledger>
is queued for handling, I<Ledger> hooks will be filtered for relevancy
and the actions inscribed in matching hooks executed.
=end item

=head3 Category: Derivative

=begin paragraph
Category I<Derivative> contains hooks designed to operate on derivative
components C<Coa> and C<Hodl>.
=end paragraph

=begin item
B<Coa>

I<Coa> hooks are scoped to C<Coa>s, aka I<Chart of Accounts>. Each time a
C<Coa> is queued for handling, I<Coa> hooks will be filtered for relevancy
and the actions inscribed in matching hooks executed.
=end item

=begin item
B<Hodl>

I<Hodl> hooks are scoped to C<Hodl>s. Each time a C<Hodl> is queued for
handling, I<Hodl> hooks will be filtered for relevancy and the actions
inscribed in matching hooks executed.
=end item

=head2 Category: Meta

=begin item
B<Hook>

I<Hook> hooks are scoped to C<Hook>s. Each time a C<Hook> is queued
for instantiation or application (e.g. C<Hook.apply>), I<Hook> hooks
will be filtered for relevancy and the actions inscribed in matching
hooks executed.

The primary impetus behind I<Hook> hooks is to log which hooks are firing
and when. I<Hook> hooks might also be used to chain hooks together.
=end item
=end pod

# end p6doc }}}

my role Common[HookType:D $type]
{...}

role Hook[POSTING]
{
    also does Hook::Action[POSTING];
    also does Hook::Trigger[POSTING];
    also does Common[POSTING];
    has HookType:D $!type = POSTING;
    method type(::?CLASS:D: --> HookType:D) { my HookType:D $type = $!type }
}

role Hook[ENTRY]
{
    also does Hook::Action[ENTRY];
    also does Hook::Trigger[ENTRY];
    also does Common[ENTRY];
    has HookType:D $!type = ENTRY;
    method type(::?CLASS:D: --> HookType:D) { my HookType:D $type = $!type }
}

role Hook[LEDGER]
{
    also does Hook::Action[LEDGER];
    also does Hook::Trigger[LEDGER];
    also does Common[LEDGER];
    has HookType:D $!type = LEDGER;
    method type(::?CLASS:D: --> HookType:D) { my HookType:D $type = $!type }
}

role Hook[COA]
{
    also does Hook::Action[COA];
    also does Hook::Trigger[COA];
    also does Common[COA];
    has HookType:D $!type = COA;
    method type(::?CLASS:D: --> HookType:D) { my HookType:D $type = $!type }
}

role Hook[HODL]
{
    also does Hook::Action[HODL];
    also does Hook::Trigger[HODL];
    also does Common[HODL];
    has HookType:D $!type = HODL;
    method type(::?CLASS:D: --> HookType:D) { my HookType:D $type = $!type }
}

role Hook[HOOK]
{
    also does Hook::Action[HOOK];
    also does Hook::Trigger[HOOK];
    also does Common[HOOK];
    has HookType:D $!type = HOOK;
    method type(::?CLASS:D: --> HookType:D) { my HookType:D $type = $!type }
}

my role Common[HookType:D $type]
{
    # for declaring C<Hook> types needed in registry
    method dependency(--> Array[Hook:U])
    {...}

    # description of hook
    method description(--> Str:D)
    {...}

    # name of hook
    method name(--> Str:D)
    {...}

    # for ordering multiple matching hooks
    method priority(--> Int:D)
    {...}

    # method perl {{{

    multi method perl(::?CLASS:D: --> Str:D)
    {
        my Str:D $perl =
            sprintf(
                Q{%s.new(%s)},
                perl('type', $type),
                perl('attr', $.name, $.description, $.priority, @.dependency)
            );
    }

    multi method perl(::?CLASS:U: --> Str:D)
    {
        my Str:D $perl = sprintf(Q{%s}, perl('type', $type));
    }

    multi sub perl(
        'type',
        HookType:D $t
        --> Str:D
    )
    {
        my Str:D $perl = sprintf(Q{Hook[%s]}, $t);
    }

    multi sub perl(
        'attr',
        Str:D $name,
        Str:D $description,
        Int:D $priority,
        Hook:U @dependency
        --> Str:D
    )
    {
        my Str:D $perl =
            sprintf(
                Q{:name(%s), :description(%s), :priority(%s), :dependency(%s)},
                $name.perl,
                $description.perl,
                $priority.perl,
                perl(@dependency)
            );
    }

    multi sub perl(
        Hook:U @ (Hook:U $dependency, *@tail),
        Str:D :carry(@c)
        --> Str:D
    )
    {
        my Hook:U @dependency = |@tail;
        my Str:D $s = perl($dependency);
        my Str:D @carry = |@c, $s;
        my Str:D $perl = perl(@dependency, :@carry);
    }

    multi sub perl(
        Hook:U @,
        Str:D :@carry
        --> Array[Str:D]
    )
    {
        my Str:D $perl = @carry.join(', ');
    }

    multi sub perl(
        Hook:U $dependency
        --> Str:D
    )
    {
        my Str:D $perl = $dependency.perl.subst(/':U'$/, '');
    }

    # end method perl }}}
}

# vim: set filetype=raku foldmethod=marker foldlevel=0:
