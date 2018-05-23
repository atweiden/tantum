use v6;
use Nightscape::Command::Clean;
use Nightscape::Command::Reup;
use Nightscape::Command::Serve;
use Nightscape::Command::Show;
use Nightscape::Command::Sync;

sub EXPORT(--> Map:D)
{
    my %EXPORT = Map.new(
        'Nightscape::Command::Clean' => Nightscape::Command::Clean,
        'Nightscape::Command::Reup'  => Nightscape::Command::Reup,
        'Nightscape::Command::Serve' => Nightscape::Command::Serve,
        'Nightscape::Command::Show'  => Nightscape::Command::Show,
        'Nightscape::Command::Sync'  => Nightscape::Command::Sync
    );
}

unit module Nightscape::Command;

# p6doc {{{

=begin pod
=head NAME

Nightscape::Command

=head DESCRIPTION

C<Nightscape::Command> exports C<Command>s.
=end pod

# end p6doc }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
