use v6;
use lib 'lib';
use Test;
use Nightscape;
use Nightscape::Config;
use Nightscape::Types;

plan 3;

my Str $config_file = "t/data/sample.conf";
our $CONF = Nightscape::Config.new(:$config_file);

# prepare assets and entities for transaction journal parsing
{
    # parse TOML config
    my %toml;
    try
    {
        use Config::TOML;
        my Str $toml_text = slurp $CONF.config_file
            or die "Sorry, couldn't read config file: ", $CONF.config_file;
        # assume UTC when local offset unspecified in TOML dates
        %toml = from-toml($toml_text, :date-local-offset(0));
        CATCH
        {
            say "Sorry, couldn't parse TOML syntax in config file: ",
                $CONF.config_file;
        }
    }

    # set base currency
    $CONF.base_currency = %toml<base-currency> if %toml<base-currency>;

    # set base costing method
    $CONF.base_costing = %toml<base-costing> if %toml<base-costing>;

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

my Str $file = "examples/sample.transactions";
my Nightscape::Entry @entries;

if $file.IO.e
{
    @entries = Nightscape.ls_entries(:$file, :sort);
}
else
{
    die "Sorry, couldn't locate file: $file";
}

{
    # entity name
    my VarName $entity_name = "Personal";

    # get entries by entity Personal
    my Nightscape::Entry @entries_by_entity_personal = Nightscape.ls_entries(
        :@entries,
        :entity(/$entity_name/)
    );

    # make entity Personal
    my Nightscape::Entity $entity_personal .= new(
        :$entity_name,
        :entries(@entries_by_entity_personal)
    );

    # generate transactions from entries by entity Personal
    $entity_personal.mktxn($_) for $entity_personal.entries;

    # execute transactions of entity Personal
    $entity_personal.transact($_) for $entity_personal.transactions;

    # the :base_currency parameter must always be passed to
    # Wallet.get_balance
    my AssetCode $bc;

    # check that the balance of entity Personal's ASSETS is -837.84 USD
    is(
        $entity_personal.wallet{ASSETS}.get_balance(
            :asset_code("USD"),
            :base_currency($bc),
            :recursive
        ),
        -837.84,
        q:to/EOF/
        ♪ [get_balance] - 1 of 3
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of:
        ┃   Success   ┃
        ┃             ┃         :asset_code("USD"),
        ┗━━━━━━━━━━━━━┛         :recursive

                           returns -837.84, as expected.
        EOF
    );

    # check that the balance of entity Personal's ASSETS is 1.91111111 BTC
    is(
        $entity_personal.wallet{ASSETS}.get_balance(
            :asset_code("BTC"),
            :base_currency($bc),
            :recursive
        ),
        1.91111111,
        q:to/EOF/
        ♪ [get_balance] - 2 of 3
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of:
        ┃   Success   ┃
        ┃             ┃         :asset_code("BTC"),
        ┗━━━━━━━━━━━━━┛         :recursive

                           returns 1.91111111, as expected.
        EOF
    );

    # check that the balance of entity Personal's BTC ASSETS is $1775.13 USD
    is(
        $entity_personal.wallet{ASSETS}.get_balance(
            :asset_code("BTC"),
            :base_currency("USD"),
            :recursive
        ),
        1775.12919888889,
        q:to/EOF/
        ♪ [get_balance] - 3 of 3
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of:
        ┃   Success   ┃
        ┃             ┃         :asset_code("BTC"),
        ┗━━━━━━━━━━━━━┛         :base_currency("USD"),
                                :recursive

                           returns 1775.12919888889, as expected.
        EOF
    );
}

# vim: ft=perl6
