use v6;
use Tantum::Hook::Action;
use Tantum::Hook::Trigger;
use Tantum::Types;
unit role Hook[HookType ::T];
also does Hook::Action[T];
also does Hook::Trigger[T];

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

I<Posting> hooks must provide a C<method apply> which accepts as
arguments:

    Entry::Posting:D $posting,
    Entry::Header:D $header,
    Hook:U :@applied,
    Entry::Postingʹ:D :@carry

and which returns:

    Hook::Response[POSTING] $response
=end item

=begin item
B<Entry>

I<Entry> hooks are scoped to C<Entry>s. Each time a new C<Entry> is
queued for handling, I<Entry> hooks will be filtered for relevancy and
the actions inscribed in matching hooks executed.

I<Entry> hooks must provide a C<method apply> which accepts as arguments:

    Entry:D $entry,
    Coa:D $coa,
    Hodl:D $hodl,
    Hook:U :@applied,
    Entryʹ:D :@carry

and which returns:

    Hook::Response[ENTRY] $response
=end item

=begin item
B<Ledger>

I<Ledger> hooks are scoped to C<Ledger>s. Each time a new C<Ledger>
is queued for handling, I<Ledger> hooks will be filtered for relevancy
and the actions inscribed in matching hooks executed.

I<Ledger> hooks must provide a C<method apply> which accepts as arguments:

    Ledger:D $ledger,
    Coa:D $coa,
    Hodl:D $hodl,
    Hook:U :@applied,
    Ledgerʹ:D :@carry

and which returns:

    Hook::Response[LEDGER] $response
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

I<Coa> hooks must provide a C<method apply> which accepts as arguments:

    Coa:D $coa,
    Entry:D $entry,
    Hodl:D $hodl,
    Hook:U :@applied,
    Coa:D :@carry

and which returns:

    Hook::Response[COA] $response
=end item

=begin item
B<Hodl>

I<Hodl> hooks are scoped to C<Hodl>s. Each time a C<Hodl> is queued for
handling, I<Hodl> hooks will be filtered for relevancy and the actions
inscribed in matching hooks executed.

I<Hodl> hooks must provide a C<method apply> which accepts as arguments:

    Hodl:D $hodl,
    Entry:D $entry,
    Hook:U :@applied,
    Hodl:D :@carry

and which returns:

    Hook::Response[HODL] $response
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

I<Hook> hooks must provide a C<method apply> which accepts as arguments:

    Str:D $enter-leave,
    Str:D $class-name,
    Str:D $routine-name,
    Capture:D $capture,
    Hook:U :@applied

and which returns:

    Hook::Response[HOOK] $response
=end item
=end pod

# end p6doc }}}

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
            perl('type', T),
            perl('attr', $.name, $.description, $.priority, @.dependency)
        );
}

multi method perl(::?CLASS:U: --> Str:D)
{
    my Str:D $perl = sprintf(Q{%s}, perl('type', T));
}

multi sub perl(
    'type',
    HookType $type
    --> Str:D
)
{
    my Str:D $perl = sprintf(Q{Hook[%s]}, $type);
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

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
