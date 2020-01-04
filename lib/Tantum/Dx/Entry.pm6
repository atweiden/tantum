use v6;
use Tantum::Dx::Entry::Posting;
use TXN::Parser::ParseTree;
unit class Entryʹ;

# p6doc {{{

=begin pod
=head NAME

Entryʹ

=head ATTRIBUTES

=head2 C<$.id>
=for paragraph
The C<Entry::ID> of C<Entry> from which C<Entryʹ> is derived.

=head2 C<$.header>
=for paragraph
The C<Entry::Header> of C<Entry> from which C<Entryʹ> is derived.

=head2 C<@.postingʹ>
=for paragraph
C<Entry::Postingʹ>s as derived from C<Entry::Posting>s of C<Entry>
from which C<Entryʹ> is derived.
=end pod

# end p6doc }}}

has Entry::ID:D $.id is required;
has Entry::Header:D $.header is required;
has Entry::Postingʹ:D @.postingʹ is required;

# vim: set filetype=raku foldmethod=marker foldlevel=0:
