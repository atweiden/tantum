use v6;
use Nightscape::Dx::Account;
use Nightscape::Dx::Coa;
use Nightscape::Dx::Entry;
use Nightscape::Dx::Hodl;
use Nightscape::Dx::Hodling;
use Nightscape::Dx::Ledger;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;

sub EXPORT(--> Map:D)
{
    my %EXPORT = Map.new(
        'Account' => Nightscape::Dx::Account,
        'Coa'     => Nightscape::Dx::Coa,
        'Hodling' => Nightscape::Dx::Hodling,
        'Hodl'    => Nightscape::Dx::Hodl,
        'Entryʹ'  => Nightscape::Dx::Entry,
        'Ledgerʹ' => Nightscape::Dx::Ledger
    );
}

unit module Nightscape::Dx;

# p6doc {{{

=begin pod
=head NAME

Nightscape::Dx

=head DESCRIPTION

C<Nightscape::Dx> exports shortnames for classes derived from
C<TXN::Parser::ParseTree>. These classes are useful in the construction
of accounting reports.
=end pod

# end p6doc }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
