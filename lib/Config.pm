use v6;
class Config;

# constants
our $data_dir = "%*ENV<HOME>/.nightscape";
our $log_dir = "$data_dir/logs";
our $price_dir = "$data_dir/prices";
our $config_dir = "%*ENV<HOME>/.config/nightscape";
our $config_file = "$config_dir/config.toml";
our $config_text = qq:to/EOCONF/;
[Default]
base-currency = "USD"

[Personal.Bankwest.Cheque]
open = "2014-01-01 .. *"

[Business]
base-currency = "USD"
open = "2014-01-02 .. *"

[Currencies.BTC.Prices.USD]
price-file = "$price_dir/coindesk-bpi-USD-close.csv"
"2014-01-01" = 770.4357
"2014-01-02" = 808.0485
"2014-01-03" = 830.024
"2014-01-04" = 858.9833
"2014-01-05" = 940.0972
"2014-01-06" = 951.3865
"2014-01-07" = 810.5833
EOCONF

method init(%c) {
    our %CONFIG = %c;
}

# vim: ft=perl6
