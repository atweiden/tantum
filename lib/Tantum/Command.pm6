use v6;
use Tantum::Command::Clean;
use Tantum::Command::Reup;
use Tantum::Command::Serve;
use Tantum::Command::Show;
use Tantum::Command::Sync;

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
