use v6;
class Nightscape::Config;

has $.config_file = "%*ENV<HOME>/.config/nightscape/config.toml";
has $.data_dir = "%*ENV<HOME>/.nightscape";
has $.log_dir = "$!data_dir/logs";
has $.price_dir = "$!data_dir/prices";

# vim: ft=perl6
