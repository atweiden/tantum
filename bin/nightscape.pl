#!/usr/bin/perl6




use v6;
use Nightscape;
use Nightscape::Config;




# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

sub MAIN($file) {
    # make config directory if it doesn't exist
    if !$Nightscape::Config::config_dir.IO.d {
        say "Config directory doesn't exist.";
        print "Creating config directory in $Nightscape::Config::config_dir… ";
        mkdir "$Nightscape::Config::config_dir" or die "Sorry, couldn't create directory $Nightscape::Config::config_dir for config. Check permissions?\n$!";
        say "done.";
    }

    # write default config file if it doesn't exist
    if !$Nightscape::Config::config_file.IO.e {
        print "Placing default config file at $Nightscape::Config::config_file… ";
        spurt $Nightscape::Config::config_file, $Nightscape::Config::config_text.trim-trailing, :createonly;
        say "done.";
    }

    # read config options
    use TOML;
    my $config_toml = slurp $Nightscape::Config::config_file or die "Sorry, could not read config file at $Nightscape::Config::config_file";
    Nightscape::Config.init(%(from-toml $config_toml));

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
