#!/usr/bin/perl6




use v6;
use Nightscape;




# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

sub MAIN($file, :$config, :$data-dir, :$log-dir, :$price-dir) {
    {
        # create default config profile
        Nightscape.mkconf;

        my %config;
        if $config {
            # check config file passed as cmdline arg exists
            if $config.IO.e {
                %config<config_file> = "$config";
            } else {
                die "Sorry, couldn't locate the given config file: $config";
            }
        } else {
            # make default config directory if it doesn't exist
            my $config_dir = IO::Path.new($Nightscape::conf.config_file).dirname;
            if !$config_dir.IO.d {
                say "Config directory doesn't exist.";
                print "Creating config directory in $config_dir… ";
                mkdir "$config_dir" or die "Sorry, couldn't create config directory: $config_dir";
                say "done.";
            }
            # write default config file if it doesn't exist
            if !$Nightscape::conf.config_file.IO.e {
                my $config_text = q:to/EOCONF/;
                base-currency = "USD"
                EOCONF
                print "Placing default config file at ", $Nightscape::conf.config_file, "… ";
                spurt $Nightscape::conf.config_file, $config_text, :createonly;
                say "done.";
            }
        }

        if $data-dir {
            # check data dir passed as cmdline arg exists
            if $data-dir.IO.d {
                %config<data_dir> = "$data-dir";
            } else {
                die "Sorry, couldn't locate the given data directory: $data-dir";
            }
        } else {
            # make default data directory if it doesn't exist
            if !$Nightscape::conf.data_dir.IO.d {
                say "Data directory doesn't exist.";
                print "Creating data directory in ", $Nightscape::conf.data_dir, "… ";
                mkdir $Nightscape::conf.data_dir or die "Sorry, couldn't create data directory: ", $Nightscape::conf.data_dir;
                say "done.";
            }
        }

        if $log-dir {
            # check log dir passed as cmdline arg exists
            if $log-dir.IO.d {
                %config<log_dir> = "$log-dir";
            } else {
                die "Sorry, couldn't locate the given log directory: $log-dir";
            }
        } else {
            # make default log directory if it doesn't exist
            if !$Nightscape::conf.log_dir.IO.d {
                say "Log directory doesn't exist.";
                print "Creating log directory in ", $Nightscape::conf.log_dir, "… ";
                mkdir $Nightscape::conf.log_dir or die "Sorry, couldn't create log directory: ", $Nightscape::conf.log_dir;
                say "done.";
            }
        }

        if $price-dir {
            # check price dir passed as cmdline arg exists
            if $price-dir.IO.d {
                %config<price_dir> = "$price-dir";
            } else {
                die "Sorry, couldn't locate the given price directory: $price-dir";
            }
        } else {
            # make default price directory if it doesn't exist
            if !$Nightscape::conf.price_dir.IO.d {
                say "Price directory doesn't exist.";
                print "Creating price directory in ", $Nightscape::conf.price_dir, "… ";
                mkdir $Nightscape::conf.price_dir or die "Sorry, couldn't create price directory: ", $Nightscape::conf.price_dir;
                say "done.";
            }
        }

        # assemble config from cmdline args
        Nightscape.mkconf(%config);
    }

    # read config options
    use TOML;
    my $config_toml = slurp $Nightscape::conf.config_file or die "Sorry, couldn't read config file: ", $Nightscape::conf.config_file;
    say qq:to/EOF/;
    Diagnostics
    ===========

    Config
    ------
    EOF
    say %(from-toml $config_toml).perl, "\n";

    if $file.IO.e {
        Nightscape.mkjournal($file);
        say qq:to/EOF/;
        Journal
        -------
        EOF
        say $Nightscape::journal;
    } else {
        die "Sorry, couldn't locate file: $file";
    }
}




# -----------------------------------------------------------------------------
# usage
# -----------------------------------------------------------------------------

sub USAGE() {
    say "Usage: nightscape.pl <File>";
}

# vim: ft=perl6
