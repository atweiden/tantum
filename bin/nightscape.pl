#!/usr/bin/perl6




use v6;




# -----------------------------------------------------------------------------
# setup
# -----------------------------------------------------------------------------

use Nightscape::Config;

# global config options, extracted from on disk conf and cmdline flags
our $CONF = Nightscape::Config.new;




# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

sub MAIN($file, :c(:$config), :$data-dir, :$log-dir, :$price-dir)
{
    # initialize config profile from cmdline args
    {
        # assemble config from cmdline args
        my %config;

        # was --config cmdline arg passed?
        if $config
        {
            # check config file passed as cmdline arg exists
            if $config.IO.e
            {
                %config<config_file> = "$config";
            }
            else
            {
                die "Sorry, couldn't locate the given config file: $config";
            }
        }
        else
        {
            # make default config directory if it doesn't exist
            my Str $config_dir = IO::Path.new($CONF.config_file).dirname;
            unless $config_dir.IO.d
            {
                say "Config directory doesn't exist.";
                print "Creating config directory in $config_dir… ";
                mkdir "$config_dir"
                    or die "Sorry, couldn't create config directory: ",
                        $config_dir;
                say "done.";
            }
            # write default config file if it doesn't exist
            unless $CONF.config_file.IO.e
            {
                my Str $config_text = q:to/EOCONF/;
                base-currency = "USD"
                EOCONF
                print "Placing default config file at ", $CONF.config_file, "… ";
                spurt $CONF.config_file, $config_text, :createonly;
                say "done.";
            }
        }

        if $data-dir
        {
            # check data dir passed as cmdline arg exists
            if $data-dir.IO.d
            {
                %config<data_dir> = "$data-dir";
            }
            else
            {
                die "Sorry, couldn't locate the given data directory: ",
                    $data-dir;
            }
        }
        else
        {
            # make default data directory if it doesn't exist
            unless $CONF.data_dir.IO.d
            {
                say "Data directory doesn't exist.";
                print "Creating data directory in ", $CONF.data_dir, "… ";
                mkdir $CONF.data_dir
                    or die "Sorry, couldn't create data directory: ",
                        $CONF.data_dir;
                say "done.";
            }
        }

        if $log-dir
        {
            # check log dir passed as cmdline arg exists
            if $log-dir.IO.d
            {
                %config<log_dir> = "$log-dir";
            }
            else
            {
                die "Sorry, couldn't locate the given log directory: ",
                    $log-dir;
            }
        }
        else
        {
            # make default log directory if it doesn't exist
            unless $CONF.log_dir.IO.d
            {
                say "Log directory doesn't exist.";
                print "Creating log directory in ", $CONF.log_dir, "… ";
                mkdir $CONF.log_dir
                    or die "Sorry, couldn't create log directory: ",
                        $CONF.log_dir;
                say "done.";
            }
        }

        if $price-dir
        {
            # check price dir passed as cmdline arg exists
            if $price-dir.IO.d
            {
                %config<price_dir> = "$price-dir";
            }
            else
            {
                die "Sorry, couldn't locate the given price directory: ",
                    $price-dir;
            }
        }
        else
        {
            # make default price directory if it doesn't exist
            unless $CONF.price_dir.IO.d
            {
                say "Price directory doesn't exist.";
                print "Creating price directory in ", $CONF.price_dir, "… ";
                mkdir $CONF.price_dir
                    or die "Sorry, couldn't create price directory: ",
                        $CONF.price_dir;
                say "done.";
            }
        }

        # apply config
        $CONF = Nightscape::Config.new(|%config);
    }

    # prepare assets and entities for transaction journal parsing
    {
        # parse TOML config
        my %toml;
        try
        {
            use TOML;
            my Str $toml_text = slurp $CONF.config_file
                or die "Sorry, couldn't read config file: ", $CONF.config_file;
            %toml = %(from-toml $toml_text);
            CATCH
            {
                say "Sorry, couldn't parse TOML syntax in config file: ",
                    $CONF.config_file;
            }
        }

        # set base currency
        my $base_currency_found = %toml<base-currency>;
        if $base_currency_found
        {
            $CONF.base_currency = %toml<base-currency>;
        }

        # set base costing method
        my $base_costing_found = %toml<base-costing>;
        if $base_costing_found
        {
            $CONF.base_costing = %toml<base-costing>;
        }

        # populate asset settings
        my %assets_found = Nightscape::Config.detoml_assets(%toml);
        if %assets_found
        {
            for %assets_found.kv -> $asset_code, $asset_data
            {
                $CONF.assets{$asset_code} = Nightscape::Config.gen_settings(
                    :$asset_code,
                    :$asset_data
                );
            }
        }

        # populate entity settings
        my %entities_found = Nightscape::Config.detoml_entities(%toml);
        if %entities_found
        {
            for %entities_found.kv -> $entity_name, $entity_data
            {
                $CONF.entities{$entity_name} = Nightscape::Config.gen_settings(
                    :$entity_name,
                    :$entity_data
                );
            }
        }
    }

    say qq:to/EOF/;
    Diagnostics
    ===========
    EOF

    if $file.IO.e
    {
        say qq:to/EOF/;
        Journal
        -------
        EOF
        use Nightscape;
        .say for Nightscape.ls_entries(:$file, :sort);
    }
    else
    {
        die "Sorry, couldn't locate file 「$file」";
    }

    say "\n", q:to/EOF/;
    Config
    ------
    EOF
    say $CONF.perl;
}




# -----------------------------------------------------------------------------
# usage
# -----------------------------------------------------------------------------

sub USAGE()
{
    my Str $help_text = q:to/EOF/;
    Usage:
      nightscape [-h] [--config=CONFIG_FILE] TRANSACTION_JOURNAL

    optional arguments:
      -c, --config=CONFIG_FILE
        the location of the configuration file
      --data-dir=DATA_DIR
        the location of the general data directory
      --log-dir=LOG_DIR
        the location of the log directory
      --price-dir=PRICE_DIR
        the location of the asset price directory
    EOF
    say $help_text.trim;
}

# vim: ft=perl6
