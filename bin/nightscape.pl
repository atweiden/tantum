#!/usr/bin/perl6




use v6;
use Nightscape;




# -----------------------------------------------------------------------------
# config
# -----------------------------------------------------------------------------

# constants
my $data_dir = "%*ENV<HOME>/.nightscape";
my $log_dir = "$data_dir/logs";
my $price_dir = "$data_dir/prices";
my $config_dir = "%*ENV<HOME>/.config/nightscape";
my $config_file = "$config_dir/config.toml";
my $config_text = qq:to/EOCONF/;
[Default]
base-currency = "USD"

[Personal]
# this group not needed, since child account exists

[Personal.Bankwest.Cheque]
# inherits base-currency from Personal:Bankwest, or Personal, or Default
#open = "2014-01-01 .. *" # optional date range (YYYY-MM-DD .. YYYY-MM-DD)

[Business]
base-currency = "USD"
open = "2014-01-02 .. *"

[Currencies.BTC.Prices.USD]
# duplicate date-price pairs overridden by date-price pairs listed by hand
price-file = "$price_dir/coindesk-bpi-USD-close.csv"
"2014-01-01" = 770.4357
"2014-01-02" = 808.0485
"2014-01-03" = 830.024
"2014-01-04" = 858.9833
"2014-01-05" = 940.0972
"2014-01-06" = 951.3865
"2014-01-07" = 810.5833
# price data given in transaction journal overrides configured date-price pairs
EOCONF




# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

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




# -----------------------------------------------------------------------------
# usage
# -----------------------------------------------------------------------------

sub USAGE() {
    say "Usage: nightscape.pl <File>";
}

# vim: ft=perl6
