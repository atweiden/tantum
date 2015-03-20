#!/usr/bin/perl6




use v6;
use Config;
use Nightscape;




# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

sub MAIN($file) {
    # make config directory if it doesn't exist
    if !$Config::config_dir.IO.d {
        say "Config directory doesn't exist.";
        print "Creating config directory in $Config::config_dir… ";
        mkdir "$Config::config_dir" or die "Sorry, couldn't create directory $Config::config_dir for config. Check permissions?\n$!";
        say "done.";
    }

    # write default config file if it doesn't exist
    if !$Config::config_file.IO.e {
        print "Placing default config file at $Config::config_file… ";
        spurt $Config::config_file, $Config::config_text.trim-trailing, :createonly;
        say "done.";
    }

    # read config options
    use TOML;
    my $config_toml = slurp $Config::config_file or die "Sorry, could not read config file at $Config::config_file";
    Config.init(%(from-toml $config_toml));

    if $file.IO.e {
        Nightscape.it($file);
    } else {
        die "Sorry, could not locate file: $file";
    }
}




# -----------------------------------------------------------------------------
# usage
# -----------------------------------------------------------------------------

sub USAGE() {
    say "Usage: nightscape.pl <File>";
}

# vim: ft=perl6
