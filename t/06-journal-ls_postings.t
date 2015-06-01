use v6;
use lib 'lib';
use Test;
use Nightscape;

plan 1;

my Str $file = "examples/sample.transactions";

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
    $nightscape.entries = $nightscape.ls_entries(:$file);
}
else
{
    die "Sorry, couldn't locate file: $file";
}

{
    use Nightscape::Types;

    # get entries by entity Personal
    my Nightscape::Entry @entries_by_entity_personal = $nightscape.ls_entries(
        :entries($nightscape.entries),
        :entity(/Personal/)
    );

    # get postings from entries by entity Personal
    my Nightscape::Entry::Posting @postings =
        $nightscape.ls_postings(:entries(@entries_by_entity_personal));

    # filter postings by asset BTC, silo ASSETS
    my Regex $asset_code = /BTC/;
    my Silo $silo = ASSETS;
    my Nightscape::Entry::Posting @postings_btc_assets =
        $nightscape.ls_postings(:@postings, :$asset_code, :$silo);

    # check that two postings are returned for asset BTC, silo ASSETS
    is(
        @postings_btc_assets.elems,
        2,
        q:to/EOF/
        ♪ [ls_postings] - 1 of 1
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of BTC:ASSETS returns 2 postings,
        ┃   Success   ┃    as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

# vim: ft=perl6
