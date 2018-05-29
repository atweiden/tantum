use v6;
use Nightscape::Command::Clean;
use Nightscape::Command::Reup;
use Nightscape::Command::Serve;
use Nightscape::Command::Show;
use Nightscape::Command::Sync;

sub EXPORT(--> Map:D)
{
    my %EXPORT = Map.new(
        'Command::Clean' => Command::Clean,
        'Command::Reup'  => Command::Reup,
        'Command::Serve' => Command::Serve,
        'Command::Show'  => Command::Show,
        'Command::Sync'  => Command::Sync
    );
}

unit module Command;

# p6doc {{{

=begin pod
=head NAME

Command

=head DESCRIPTION

C<Command> exports C<Command>s.
=end pod

# end p6doc }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
