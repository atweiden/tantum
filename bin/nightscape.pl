#!/usr/bin/perl6

use v6;
use Nightscape;

my $config_dir = "%*ENV<HOME>/.config/nightscape";
my $config_file = "$config_dir/config.pl";

sub MAIN($file) {
    # make config directory if it doesn't exist
    if !$config_dir.IO.d {
        say "Config directory doesn't exist.";
        print "Creating config directory in $config_dir… ";
        mkdir "$config_dir" or die "Sorry, couldn't create directory $config_dir for config. Check permissions?\n$!";
        say "done.";
    }

    # write default config file if it doesn't exist
    if !$config_file.IO.e {
        print "Placing default config file at $config_file… ";
        say "done.";
    }

    # read config options

    if $file.IO.e {
        Nightscape.it($file);
    } else {
        die "Sorry, could not locate file: $file";
    }
}

sub USAGE() {
    say "Usage: nightscape.pl <File>";
}

# vim: ft=perl6
