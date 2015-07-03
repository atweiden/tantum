use v6;
use lib 'lib';
use Test;
use Nightscape;
use Nightscape::Config;
use Nightscape::Types;
use UUID;

plan 1;

our $CONF = Nightscape::Config.new;

# prepare assets and entities for transaction journal parsing
{
    # parse TOML config
    my %toml;
    try
    {
        use TOML;
        my $toml_text = slurp $CONF.config_file
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

my Str $file = "t/data/sensible.transactions";
my Nightscape::Entity @entities;
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
    # list unique entity names
    my VarName @entity_names = Nightscape.ls_entity_names(:@entries);
    for @entity_names -> $entity_name
    {
        # instantiate Entity
        my Nightscape::Entity $entity .= new(:$entity_name);

        # get entries by Entity
        my Nightscape::Entry @entries_entity = Nightscape.ls_entries(
            :@entries,
            :entity(/$entity_name/)
        );

        # instantiate transactions by Entity
        my Nightscape::Entity::TXN @transactions;
        push @transactions, $entity.gen_txn(:entry($_)) for @entries_entity;

        # exec transactions by Entity
        $entity.transact(:transaction($_)) for @transactions;

        # make chart of accounts for Entity
        $entity.mkcoa;

        # store entity
        push @entities, $entity;

        say '[Assets]';
        say 'Assets.USD: USD ', $entity.coa.wllt{ASSETS}.get_balance(
            :asset_code("USD"),
            :recursive
        );
        say 'Assets.LTC: USD ', $entity.coa.wllt{ASSETS}.get_balance(
            :asset_code("LTC"),
            :base_currency("USD"),
            :recursive
        ), ' 「LTC ', $entity.coa.wllt{ASSETS}.get_balance(
            :asset_code("LTC"),
            :recursive
        ), '」';

        say '';
        say '[Income]';
        say 'Income.USD: USD ', $entity.coa.wllt{INCOME}.get_balance(
            :asset_code("USD"),
            :recursive
        );
        say 'Income.LTC: USD ', $entity.coa.wllt{INCOME}.get_balance(
            :asset_code("LTC"),
            :base_currency("USD"),
            :recursive
        ), ' 「LTC ', $entity.coa.wllt{INCOME}.get_balance(
            :asset_code("LTC"),
            :recursive
        ), '」';

        say '';
        say '[Equity]';
        say 'Equity.USD: USD ', $entity.coa.wllt{EQUITY}.get_balance(
            :asset_code("USD"),
            :recursive
        );
        say 'Equity.LTC: USD ', $entity.coa.wllt{EQUITY}.get_balance(
            :asset_code("LTC"),
            :base_currency("USD"),
            :recursive
        ), ' 「LTC ', $entity.coa.wllt{EQUITY}.get_balance(
            :asset_code("LTC"),
            :recursive
        ), '」';
    }
}

say $_.perl for @entities[0].tree(:wallet(@entities[0].coa.wllt));

my Rat %balance{Silo} = @entities[0].get_eqbal;

is(
    %balance{ASSETS} + %balance{EXPENSES},
    %balance{INCOME} + %balance{LIABILITIES} + %balance{EQUITY},
    q:to/EOF/
    ♪ [get_eqbal] - 1 of 1
    ┏━━━━━━━━━━━━━┓
    ┃             ┃  ∙ Fundamental accounting equation balances,
    ┃   Success   ┃    as expected.
    ┃             ┃
    ┗━━━━━━━━━━━━━┛
    EOF
);

# Entity.wallet should remain true to the original
# this is still buggy
# say @entities[0].wallet.perl;
# say "\n" x 3;
# say @entities[0].coa.wllt.perl;

# vim: ft=perl6
