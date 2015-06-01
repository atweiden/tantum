#!/usr/bin/perl6




use v6;




# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------

sub MAIN($file, :c(:$config), :$data-dir, :$log-dir, :$price-dir)
{
    use Nightscape;
    my Nightscape $nightscape = Nightscape.new;

    # initialize config profile from cmdline args
    {
        # create default config profile
        use Nightscape::Config;
        $nightscape.conf = Nightscape::Config.new;

        # assemble config from cmdline args
        my %config;
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
            my $config_dir = IO::Path.new(
                $nightscape.conf.config_file
            ).dirname;
            if !$config_dir.IO.d
            {
                say "Config directory doesn't exist.";
                print "Creating config directory in $config_dir… ";
                mkdir "$config_dir"
                    or die "Sorry, couldn't create config directory: ",
                        $config_dir;
                say "done.";
            }
            # write default config file if it doesn't exist
            if !$nightscape.conf.config_file.IO.e
            {
                my $config_text = q:to/EOCONF/;
                base-currency = "USD"
                EOCONF
                print "Placing default config file at ",
                    $nightscape.conf.config_file, "… ";
                spurt $nightscape.conf.config_file, $config_text, :createonly;
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
            if !$nightscape.conf.data_dir.IO.d
            {
                say "Data directory doesn't exist.";
                print "Creating data directory in ",
                    $nightscape.conf.data_dir, "… ";
                mkdir $nightscape.conf.data_dir
                    or die "Sorry, couldn't create data directory: ",
                        $nightscape.conf.data_dir;
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
            if !$nightscape.conf.log_dir.IO.d
            {
                say "Log directory doesn't exist.";
                print "Creating log directory in ",
                    $nightscape.conf.log_dir, "… ";
                mkdir $nightscape.conf.log_dir
                    or die "Sorry, couldn't create log directory: ",
                        $nightscape.conf.log_dir;
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
            if !$nightscape.conf.price_dir.IO.d
            {
                say "Price directory doesn't exist.";
                print "Creating price directory in ",
                    $nightscape.conf.price_dir, "… ";
                mkdir $nightscape.conf.price_dir
                    or die "Sorry, couldn't create price directory: ",
                        $nightscape.conf.price_dir;
                say "done.";
            }
        }

        # apply config
        $nightscape.conf = Nightscape::Config.new(|%config);
    }

    # prepare assets and entities for transaction journal parsing
    {
        # parse TOML config
        my %toml;
        try
        {
            use TOML;
            my $toml_text = slurp $nightscape.conf.config_file
                or die "Sorry, couldn't read config file: ",
                    $nightscape.conf.config_file;
            %toml = %(from-toml $toml_text);
            CATCH
            {
                say "Sorry, couldn't parse TOML syntax in config file: ",
                    $nightscape.conf.config_file;
            }
        }

        # set base currency from mandatory toplevel config directive
        $nightscape.conf.base_currency = %toml<base-currency>
            or die "Sorry, could not find global base-currency",
                " in config (mandatory).";

        # populate asset prices
        for $nightscape.conf.detoml_assets(%toml).kv -> $code, $prices
        {
            $nightscape.conf.assets{$code} =
                $nightscape.conf.gen_pricesheet( prices => $prices<Prices> );
        }

        # populate entities
        for $nightscape.conf.detoml_entities(%toml).kv -> $name, $rest
        {
            $nightscape.conf.entities{$name} = $rest;
        }
    }

    say qq:to/EOF/;
    Diagnostics
    ===========
    EOF

    if $file.IO.e
    {
        $nightscape.entries = $nightscape.ls_entries(:$file, :sort);

        say qq:to/EOF/;
        Journal
        -------
        EOF
        say $nightscape.entries.perl;
    }
    else
    {
        die "Sorry, couldn't locate file: $file";
    }

    say "\n", q:to/EOF/;
    Config
    ------
    EOF
    say $nightscape.conf.perl;
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
