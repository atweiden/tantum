use v6;
use lib 'lib';
use Test;
use Nightscape;
use Nightscape::Config;
use Nightscape::Types;

plan 3;

my Str $config-file = "t/data/sample.conf";
our $CONF = Nightscape::Config.new(:$config-file);

# prepare assets and entities for transaction journal parsing
{
    # parse TOML config
    my %toml;
    try
    {
        use Config::TOML;
        my Str $toml-text = slurp $CONF.config-file
            or die "Sorry, couldn't read config file: ", $CONF.config-file;
        # assume UTC when local offset unspecified in TOML dates
        %toml = from-toml($toml-text, :date-local-offset(0));
        CATCH
        {
            say "Sorry, couldn't parse TOML syntax in config file: ",
                $CONF.config-file;
        }
    }

    # set base currency
    $CONF.base-currency = %toml<base-currency> if %toml<base-currency>;

    # set base costing method
    $CONF.base-costing = %toml<base-costing> if %toml<base-costing>;

    # populate asset settings
    my %assets-found = Nightscape::Config.detoml-assets(%toml);
    if %assets-found
    {
        for %assets-found.kv -> $asset-code, $asset-data
        {
            $CONF.assets{$asset-code} = Nightscape::Config.gen-settings(
                :$asset-code,
                :$asset-data
            );
        }
    }

    # populate entity settings
    my %entities-found = Nightscape::Config.detoml-entities(%toml);
    if %entities-found
    {
        for %entities-found.kv -> $entity-name, $entity-data
        {
            $CONF.entities{$entity-name} = Nightscape::Config.gen-settings(
                :$entity-name,
                :$entity-data
            );
        }
    }
}

my Str $file = "examples/sample/sample.txn";
my Nightscape::Entry @entries;

if $file.IO.e
{
    @entries = Nightscape.ls-entries(:txn(slurp $file), :sort);
}
else
{
    die "Sorry, couldn't locate file: $file";
}

{
    # entity name
    my VarName $entity-name = "Personal";

    # get entries by entity Personal
    my Nightscape::Entry @entries-by-entity-personal = Nightscape.ls-entries(
        :@entries,
        :entity(/$entity-name/)
    );

    # make entity Personal
    my Nightscape::Entity $entity-personal .= new(
        :$entity-name,
        :entries(@entries-by-entity-personal)
    );

    # generate transactions from entries by entity Personal
    $entity-personal.mktxn($_) for $entity-personal.entries;

    # execute transactions of entity Personal
    $entity-personal.transact($_) for $entity-personal.transactions;

    # the :base-currency parameter must always be passed to
    # Wallet.get-balance
    my AssetCode $bc;

    # check that the balance of entity Personal's ASSETS is -837.84 USD
    is(
        $entity-personal.wallet{ASSETS}.get-balance(
            :asset-code("USD"),
            :base-currency($bc),
            :recursive
        ),
        -837.84,
        q:to/EOF/
        ♪ [get-balance] - 1 of 3
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of:
        ┃   Success   ┃
        ┃             ┃         :asset-code("USD"),
        ┗━━━━━━━━━━━━━┛         :recursive

                           returns -837.84, as expected.
        EOF
    );

    # check that the balance of entity Personal's ASSETS is 1.91111111 BTC
    is(
        $entity-personal.wallet{ASSETS}.get-balance(
            :asset-code("BTC"),
            :base-currency($bc),
            :recursive
        ),
        1.91111111,
        q:to/EOF/
        ♪ [get-balance] - 2 of 3
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of:
        ┃   Success   ┃
        ┃             ┃         :asset-code("BTC"),
        ┗━━━━━━━━━━━━━┛         :recursive

                           returns 1.91111111, as expected.
        EOF
    );

    # check that the balance of entity Personal's BTC ASSETS is $1775.13 USD
    is(
        $entity-personal.wallet{ASSETS}.get-balance(
            :asset-code("BTC"),
            :base-currency("USD"),
            :recursive
        ),
        1775.12919888889,
        q:to/EOF/
        ♪ [get-balance] - 3 of 3
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of:
        ┃   Success   ┃
        ┃             ┃         :asset-code("BTC"),
        ┗━━━━━━━━━━━━━┛         :base-currency("USD"),
                                :recursive

                           returns 1775.12919888889, as expected.
        EOF
    );
}

# vim: ft=perl6
