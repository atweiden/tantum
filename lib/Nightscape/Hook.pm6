use v6;
use TXN::Parser::Types;
unit class Nightscape::Hook;

# p6doc {{{

=begin pod
=head NAME

Nightscape::Hook

=head DESCRIPTION

=begin paragraph
Hooks are the primary means by which Nightscape takes a list of
standard TXN C<Entry>s parsed from a plain-text TXN document, and
feeds it through a pipeline of transformations. This pipeline
produces a I<Chart of Accounts> and other essential accounting
reports.

Hooks allow for closely examining and logging each and every step
a TXN document goes along the way to an essential report, leading
to increased auditability. Hooks give us fine-grained control over
what happens every step of the way to any essential report.
=end paragraph

=head2 Hooks By Category

=head3 Category: TXN Primitives

=begin paragraph
Category I<TXN Primitives> contains hooks designed to operate on
TXN primitives C<Entry::Posting>, C<Entry>, and C<Ledger>; these
hooks are tasked with generating derivatives C<Entry::Postingʹ> and
C<Entryʹ> respectively. I<Ledger> hooks are TBD.
=end paragraph

=begin item
B<Posting>

I<Posting> hooks are scoped to C<Entry::Posting>s. Each time a new
C<Entry::Posting> is queued for derivative (C<Entry::Postingʹ>)
generation, I<Posting> hooks will be filtered for relevancy and the
actions inscribed in matching hooks executed.

I<Posting> hooks must provide a C<method new> which accepts as
arguments:

    Entry::Posting:D $posting
    Coa:D $coa
    Hodl:D $hodl

and which returns:

    Entry::Postingʹ:D $postingʹ
=end item

=begin item
B<Entry>

I<Entry> hooks are scoped to C<Entry>s. Each time a new C<Entry>
is queued for derivative (C<Entryʹ>) generation, I<Entry> hooks
will be filtered for relevancy and the actions inscribed in matching
hooks executed.

I<Entry> hooks must provide a C<method new> which accepts as
arguments:

    Entry:D $entry
    Entry::Postingʹ:D @postingʹ

and which returns:

    Entryʹ:D $entryʹ
=end item

=begin item
B<Ledger>

I<Ledger> hooks are scoped to C<Ledger>s. A C<Ledger> is a fully
assembled TXN document consisting of disparate C<Entry>s. Each time
a new C<Ledger> is queued for instantiation, I<Ledger> hooks will
be filtered for relevancy and the actions inscribed in matching
hooks executed.
=end item

=head3 Category: Derivative Components

=begin paragraph
Category I<Derivative Components> contains hooks designed to operate
on derivative components C<Coa> and C<Hodl>; these hooks are tasked
with generating essential components of derivatives C<Entry::Postingʹ>
and C<Entryʹ>.

For example, a I<Coa> hook could check for a sufficient balance on
an Asset account before crediting the account.
=end paragraph

=begin item
B<Coa>

I<Coa> hooks are scoped to C<Coa>s, aka I<Chart of Accounts>. Each
time a C<Coa> is queued for instantiation (e.g. as part of C<Entryʹ>
or C<Entry::Postingʹ> generation), I<Coa> hooks will be filtered
for relevancy and the actions inscribed in matching hooks executed.

I<Coa> hooks must provide a C<method new> which accepts as arguments:

    # an existing Coa
    Coa:D $c
    Entry::Posting:D @posting

and which returns:

    # a new Coa if applicable
    Coa:D $coa
=end item

=begin item
B<Hodl>

I<Hodl> hooks are scoped to C<Hodl>s. Each time a C<Hodl> is queued
for instantiation (e.g. as part of C<Entryʹ> generation), I<Coa>
hooks will be filtered for relevancy and the actions inscribed in
matching hooks executed.
=end item
=end pod

# end p6doc }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
