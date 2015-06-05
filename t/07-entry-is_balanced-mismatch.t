use v6;
use lib 'lib';
use Test;
use Nightscape;
use Nightscape::Config;

plan 2;

my Str $file = "t/data/invalid.transactions";

my Nightscape $nightscape = Nightscape.new(
    conf => Nightscape::Config.new(
        base_currency => "USD"
    )
);

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

if $file.IO.e
{
    $nightscape.entries = $nightscape.ls_entries(:$file, :sort);
}
else
{
    die "Sorry, couldn't locate file: $file";
}

{
    # make entity Personal
    my Nightscape::Entity $entity_personal = Nightscape::Entity.new;

    # get entries by entity Personal
    my @entries_by_entity_personal = $nightscape.ls_entries(
        :entries($nightscape.entries),
        :entity(/Personal/)
    );

    # check that entry id 3 of data/invalid.transactions causes exchange
    # rate mismatch error
    dies-ok { @entries_by_entity_personal[3].is_balanced($nightscape.conf) },
            q:to/EOF/;
            ♪ [is_balanced-mismatch] - 1 of 2
            ┏━━━━━━━━━━━━━┓
            ┃             ┃  ∙ Passed argument of @entries_by_entity_personal[3]
            ┃   Success   ┃    causes exchange rate mismatch error, as expected.
            ┃             ┃
            ┗━━━━━━━━━━━━━┛
            EOF

    # check that entry id 4 of data/invalid.transactions causes exchange
    # rate mismatch error
    dies-ok { @entries_by_entity_personal[4].is_balanced($nightscape.conf) },
            q:to/EOF/;
            ♪ [is_balanced-mismatch] - 2 of 2
            ┏━━━━━━━━━━━━━┓
            ┃             ┃  ∙ Passed argument of @entries_by_entity_personal[4]
            ┃   Success   ┃    causes exchange rate mismatch error, as expected.
            ┃             ┃
            ┗━━━━━━━━━━━━━┛
            EOF
}

# vim: ft=perl6
