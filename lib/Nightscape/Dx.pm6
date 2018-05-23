use v6;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
unit module Nightscape::Dx;

# p6doc {{{

=begin pod
=head NAME

Nightscape::Dx

=head DESCRIPTION

C<Nightscape::Dx> exports shortnames for classes derived from
C<TXN::Parser::ParseTree>. These classes are useful in the construction
of accounting reports.

=head NYI

    # XXX not yet working
    use Nightscape::Dx::Account;
    use Nightscape::Dx::Coa;
    use Nightscape::Dx::Hodling;
    use Nightscape::Dx::Hodl;
    use Nightscape::Dx::Entryʹ;
    use Nightscape::Dx::Ledgerʹ;
    sub EXPORT(--> Map:D)
    {
        my %EXPORT = Map.new(
            'Account' => Account,
            'Coa'     => Coa,
            'Hodling' => Hodling,
            'Hodl'    => Hodl,
            'Entryʹ'  => Entryʹ,
            'Ledgerʹ' => Ledgerʹ
        );
    }
    unit module Nightscape::Dx;

=end pod

# end p6doc }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
