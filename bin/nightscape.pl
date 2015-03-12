#!/usr/bin/perl6

use v6;
use Nightscape;

sub MAIN($file) {
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
