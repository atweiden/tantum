use v6;
use Tantum::Dx::Account;
use Tantum::Dx::Coa;
use Tantum::Dx::Entry::Posting::Meta;
use Tantum::Dx::Entry::Posting;
use Tantum::Dx::Entry;
use Tantum::Dx::Hodl;
use Tantum::Dx::Hodling::Basis::Lot;
use Tantum::Dx::Hodling::Basis;
use Tantum::Dx::Hodling;
use Tantum::Dx::Ledger;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;

sub EXPORT(--> Map:D)
{
    my %EXPORT = Map.new(
        'Account'               => Account,
        'Coa'                   => Coa,
        'Entry::Postingʹ'       => Entry::Postingʹ,
        'Entry::Postingʹ::Meta' => Entry::Postingʹ::Meta,
        'Entryʹ'                => Entryʹ,
        'Hodl'                  => Hodl,
        'Hodling'               => Hodling,
        'Hodling::Basis'        => Hodling::Basis,
        'Hodling::Basis::Lot'   => Hodling::Basis::Lot,
        'Ledgerʹ'               => Ledgerʹ
    );
}

unit module Tantum::Dx;

# p6doc {{{

=begin pod
=head NAME

Tantum::Dx

=head DESCRIPTION

C<Tantum::Dx> exports shortnames for classes derived from
C<TXN::Parser::ParseTree>. These classes are useful in the construction
of accounting reports.
=end pod

# end p6doc }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
