use v6;
use Nightscape::Hook::Action;
use Nightscape::Hook::Trigger;
use Nightscape::Types;
unit role Nightscape::Hook[HookType $type];
also does Nightscape::Hook::Action[$type];
also does Nightscape::Hook::Trigger[$type];

# p6doc {{{

=begin pod
=head NAME

Nightscape::Hook

=head DESCRIPTION

=begin paragraph
Hooks are the primary means by which Nightscape produces essential
accounting reports. Through hooks, Nightscape can take a list of C<Entry>s
parsed from a plain-text TXN document and convert it into usable data,
e.g. a I<Chart of Accounts>.

Hooks allow for closely examining and logging each and every step a TXN
document goes through along the way to an essential report, leading to
increased auditability.

Pure functions are to be strived for. Side-effects during pipeline
transformation at the behest of Hooks are strongly discouraged.
Major datapoints, such as I<Chart of Accounts> (C<Coa>) and I<Holdings>
(C<Hodl>) are first class citizens throughout the entirety of the
pipeline, for instance. If and when other data structures become critical
to Nightscape report generation, the key elements of those data structures
should be reined in similar to how C<Coa> and C<Hodl> are handled.
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

    Entry::Posting:D $p,
    Entry::Header:D $header

and which returns:

    Entry::Posting:D $posting
=end item

=begin item
B<Entry>

I<Entry> hooks are scoped to C<Entry>s. Each time a new C<Entry> is
queued for handling, I<Entry> hooks will be filtered for relevancy and
the actions inscribed in matching hooks executed.

I<Entry> hooks must provide a C<method apply> which accepts as arguments:

    Entry:D $entry,
    Coa:D $coa,
    Hodl:D $hodl

and which returns:

    Entryʹ:D $entryʹ
=end item

=begin item
B<Ledger>

I<Ledger> hooks are scoped to C<Ledger>s. Each time a new C<Ledger>
is queued for handling, I<Ledger> hooks will be filtered for relevancy
and the actions inscribed in matching hooks executed.

I<Ledger> hooks must provide a C<method apply> which accepts as arguments:

    Ledger:D $ledger,
    Coa:D $coa,
    Hodl:D $hodl

and which returns:

    Ledgerʹ:D $ledgerʹ
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

    Coa:D $c,
    Entry:D $entry,
    Hodl:D $hodl

and which returns:

    Coa:D $coa
=end item

=begin item
B<Hodl>

I<Hodl> hooks are scoped to C<Hodl>s. Each time a C<Hodl> is queued for
handling, I<Hodl> hooks will be filtered for relevancy and the actions
inscribed in matching hooks executed.

I<Hodl> hooks must provide a C<method apply> which accepts as arguments:

    Hodl:D $h,
    Entry:D $entry

and which returns:

    Hodl:D $hodl
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

    Str:D $class-name,
    Str:D $routine-name,
    Capture:D $capture

and which returns:

    Nil
=end item
=end pod

# end p6doc }}}

# name of hook
method name(--> Str:D)
{...}

# description of hook
method description(--> Str:D)
{...}

# for ordering multiple matching hooks
method priority(--> Int:D)
{...}

# for declaring C<Nightscape::Hook> types needed in registry
method dependency(--> Array[Nightscape::Hook:U])
{...}

# method perl {{{

method perl(--> Str:D)
{
    my Str:D $perl =
        sprintf(
            Q{%s.new(%s)},
            perl('type', $type),
            perl('attr', $.name, $.description, $.priority, @.dependency)
        );
}

multi sub perl(
    'type',
    HookType $type
    --> Str:D
)
{
    my Str:D $perl = sprintf(Q{Nightscape::Hook[%s]}, $type);
}

multi sub perl(
    'attr',
    Str:D $name,
    Str:D $description,
    Int:D $priority,
    Nightscape::Hook:U @dependency
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
    Nightscape::Hook:U @ (Nightscape::Hook:U $dependency, *@tail),
    Str:D :carry(@c)
    --> Str:D
)
{
    my Nightscape::Hook:U @dependency = |@tail;
    my Str:D $s = perl($dependency);
    my Str:D @carry = |@c, $s;
    my Str:D $perl = perl(@dependency, :@carry);
}

multi sub perl(
    Nightscape::Hook:U @,
    Str:D :@carry
    --> Array[Str:D]
)
{
    my Str:D $perl = @carry.join(', ');
}

multi sub perl(
    Nightscape::Hook:U $dependency
    --> Str:D
)
{
    my Str:D $perl = $dependency.perl.subst(/':U'$/, '');
}

# end method perl }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
