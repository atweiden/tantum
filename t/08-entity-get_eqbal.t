use v6;
use lib 'lib';
use Test;
use Nightscape;
use Nightscape::Config;
use Nightscape::Types;

plan 2;

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

my Str $file = "t/data/sensible.txn";
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
        # get entries by Entity
        my Nightscape::Entry @entries_entity = Nightscape.ls_entries(
            :@entries,
            :entity(/$entity_name/)
        );

        # instantiate Entity
        my Nightscape::Entity $entity .= new(
            :$entity_name,
            :entries(@entries_entity)
        );

        # instantiate transactions by Entity
        $entity.mktxn($_) for $entity.entries;

        # exec transactions by Entity
        $entity.transact($_) for $entity.transactions;

        # make chart of accounts for Entity
        $entity.mkcoa;

        # store entity
        push @entities, $entity;

        # say 'Entity.wallet';
        # say '[Assets]';
        # say 'Assets.USD: USD ', $entity.wallet{ASSETS}.get_balance(
        #     :asset_code("USD"),
        #     :recursive
        # );
        # say 'Assets.LTC: USD ', $entity.wallet{ASSETS}.get_balance(
        #     :asset_code("LTC"),
        #     :base_currency("USD"),
        #     :recursive
        # ), ' 「LTC ', $entity.wallet{ASSETS}.get_balance(
        #     :asset_code("LTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Income]';
        # say 'Income.USD: USD ', $entity.wallet{INCOME}.get_balance(
        #     :asset_code("USD"),
        #     :recursive
        # );
        # say 'Income.LTC: USD ', $entity.wallet{INCOME}.get_balance(
        #     :asset_code("LTC"),
        #     :base_currency("USD"),
        #     :recursive
        # ), ' 「LTC ', $entity.wallet{INCOME}.get_balance(
        #     :asset_code("LTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Equity]';
        # say 'Equity.USD: USD ', $entity.wallet{EQUITY}.get_balance(
        #     :asset_code("USD"),
        #     :recursive
        # );
        # say 'Equity.LTC: USD ', $entity.wallet{EQUITY}.get_balance(
        #     :asset_code("LTC"),
        #     :base_currency("USD"),
        #     :recursive
        # ), ' 「LTC ', $entity.wallet{EQUITY}.get_balance(
        #     :asset_code("LTC"),
        #     :recursive
        # ), '」';

        # say "\n" x 3;
        # say '[Assets]';
        # say 'Assets.USD: USD ', $entity.coa.wllt{ASSETS}.get_balance(
        #     :asset_code("USD"),
        #     :recursive
        # );
        # say 'Assets.LTC: USD ', $entity.coa.wllt{ASSETS}.get_balance(
        #     :asset_code("LTC"),
        #     :base_currency("USD"),
        #     :recursive
        # ), ' 「LTC ', $entity.coa.wllt{ASSETS}.get_balance(
        #     :asset_code("LTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Income]';
        # say 'Income.USD: USD ', $entity.coa.wllt{INCOME}.get_balance(
        #     :asset_code("USD"),
        #     :recursive
        # );
        # say 'Income.LTC: USD ', $entity.coa.wllt{INCOME}.get_balance(
        #     :asset_code("LTC"),
        #     :base_currency("USD"),
        #     :recursive
        # ), ' 「LTC ', $entity.coa.wllt{INCOME}.get_balance(
        #     :asset_code("LTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Equity]';
        # say 'Equity.USD: USD ', $entity.coa.wllt{EQUITY}.get_balance(
        #     :asset_code("USD"),
        #     :recursive
        # );
        # say 'Equity.LTC: USD ', $entity.coa.wllt{EQUITY}.get_balance(
        #     :asset_code("LTC"),
        #     :base_currency("USD"),
        #     :recursive
        # ), ' 「LTC ', $entity.coa.wllt{EQUITY}.get_balance(
        #     :asset_code("LTC"),
        #     :recursive
        # ), '」';
    }
}

# say "Entity: ", @entities[0].entity_name;
# say $_.perl for @entities[0].tree(:wallet(@entities[0].coa.wllt));

# if drift is negative, then INCOME + LIABILITIES + EQUITY outweighs
# ASSETS + EXPENSES, because INCOME, LIABILITIES and EQUITY have a
# -1 multiplier
my FatRat $drift = [+] (.drift for @entities[0].transactions);

my FatRat %balance{Silo} = @entities[0].get_eqbal(
    :wallet(@entities[0].coa.wllt)
    :acct(@entities[0].coa.acct)
);
# say "Entity.coa.wllt eqbal: ", %balance.perl;

# my FatRat %balance_orig{Silo} = @entities[0].get_eqbal(
#     :wallet(@entities[0].wallet)
# );
# say "Entity.wallet eqbal: ", %balance_orig.perl;

is(
    %balance{ASSETS} + %balance{EXPENSES},
    %balance{INCOME} + %balance{LIABILITIES} + %balance{EQUITY},
    q:to/EOF/
    ♪ [get_eqbal] - 1 of 2
    ┏━━━━━━━━━━━━━┓
    ┃             ┃  ∙ Fundamental accounting equation balances,
    ┃   Success   ┃    as expected.
    ┃             ┃
    ┗━━━━━━━━━━━━━┛
    EOF
);

# Entity.wallet should remain true to the original
# say @entities[0].wallet.perl;
# say "\n" x 3;
# say @entities[0].coa.wllt.perl;

my Str $file_advanced = "t/data/bad-form-multi-topic.txn";
my Nightscape::Entity @entities_advanced;
my Nightscape::Entry @entries_advanced;

if $file_advanced.IO.e
{
    @entries_advanced = Nightscape.ls_entries(:file($file_advanced), :sort);
}
else
{
    die "Sorry, couldn't locate file: $file_advanced";
}

{
    # list unique entity names
    my VarName @entity_names = Nightscape.ls_entity_names(
        :entries(@entries_advanced)
    );
    for @entity_names -> $entity_name
    {
        # get entries by Entity
        my Nightscape::Entry @entries_entity = Nightscape.ls_entries(
            :entries(@entries_advanced),
            :entity(/$entity_name/)
        );

        # instantiate Entity
        my Nightscape::Entity $entity .= new(
            :$entity_name,
            :entries(@entries_entity)
        );

        # instantiate transactions by Entity
        $entity.mktxn($_) for $entity.entries;

        # exec transactions by Entity
        $entity.transact($_) for $entity.transactions;

        # make chart of accounts for Entity
        $entity.mkcoa;

        # store entity
        push @entities_advanced, $entity;

        # say 'Entity.wallet';
        # say '[Assets]';
        # say 'Assets.USD: USD ', $entity.wallet{ASSETS}.get_balance(
        #     :asset_code("USD"),
        #     :recursive
        # );
        # say 'Assets.BTC: USD ', $entity.wallet{ASSETS}.get_balance(
        #     :asset_code("BTC"),
        #     :base_currency("USD"),
        #     :recursive
        # ), ' 「BTC ', $entity.wallet{ASSETS}.get_balance(
        #     :asset_code("BTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Income]';
        # say 'Income.USD: USD ', $entity.wallet{INCOME}.get_balance(
        #     :asset_code("USD"),
        #     :recursive
        # );
        # say 'Income.BTC: USD ', $entity.wallet{INCOME}.get_balance(
        #     :asset_code("BTC"),
        #     :base_currency("USD"),
        #     :recursive
        # ), ' 「BTC ', $entity.wallet{INCOME}.get_balance(
        #     :asset_code("BTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Equity]';
        # say 'Equity.USD: USD ', $entity.wallet{EQUITY}.get_balance(
        #     :asset_code("USD"),
        #     :recursive
        # );
        # say 'Equity.BTC: USD ', $entity.wallet{EQUITY}.get_balance(
        #     :asset_code("BTC"),
        #     :base_currency("USD"),
        #     :recursive
        # ), ' 「BTC ', $entity.wallet{EQUITY}.get_balance(
        #     :asset_code("BTC"),
        #     :recursive
        # ), '」';

        # say "\n" x 3;
        # say '[Assets]';
        # say 'Assets.USD: USD ', $entity.coa.wllt{ASSETS}.get_balance(
        #     :asset_code("USD"),
        #     :recursive
        # );
        # say 'Assets.BTC: USD ', $entity.coa.wllt{ASSETS}.get_balance(
        #     :asset_code("BTC"),
        #     :base_currency("USD"),
        #     :recursive
        # ), ' 「BTC ', $entity.coa.wllt{ASSETS}.get_balance(
        #     :asset_code("BTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Income]';
        # say 'Income.USD: USD ', $entity.coa.wllt{INCOME}.get_balance(
        #     :asset_code("USD"),
        #     :recursive
        # );
        # say 'Income.BTC: USD ', $entity.coa.wllt{INCOME}.get_balance(
        #     :asset_code("BTC"),
        #     :base_currency("USD"),
        #     :recursive
        # ), ' 「BTC ', $entity.coa.wllt{INCOME}.get_balance(
        #     :asset_code("BTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Equity]';
        # say 'Equity.USD: USD ', $entity.coa.wllt{EQUITY}.get_balance(
        #     :asset_code("USD"),
        #     :recursive
        # );
        # say 'Equity.BTC: USD ', $entity.coa.wllt{EQUITY}.get_balance(
        #     :asset_code("BTC"),
        #     :base_currency("USD"),
        #     :recursive
        # ), ' 「BTC ', $entity.coa.wllt{EQUITY}.get_balance(
        #     :asset_code("BTC"),
        #     :recursive
        # ), '」';
    }
}

# say $_.perl for @entities_advanced[0].tree(:wallet(@entities_advanced[0].coa.wllt));

my FatRat $drift_advanced = [+] (.drift for @entities_advanced[0].transactions);
my FatRat %balance_advanced{Silo} = @entities_advanced[0].get_eqbal(
    :wallet(@entities_advanced[0].coa.wllt)
    :acct(@entities_advanced[0].coa.acct)
);
# say "Entity.coa.wllt eqbal: ", %balance_advanced.perl;

# my FatRat %balance_advanced_orig{Silo} = @entities_advanced[0].get_eqbal(
#     :wallet(@entities_advanced[0].wallet)
# );
# say "Entity.wallet eqbal: ", %balance_advanced_orig.perl;

is(
    %balance_advanced{ASSETS} + %balance_advanced{EXPENSES},
    %balance_advanced{INCOME} + %balance_advanced{LIABILITIES}
        + %balance_advanced{EQUITY} + $drift_advanced,
    q:to/EOF/
    ♪ [get_eqbal] - 2 of 2
    ┏━━━━━━━━━━━━━┓
    ┃             ┃  ∙ Fundamental accounting equation balances,
    ┃   Success   ┃    as expected.
    ┃             ┃
    ┗━━━━━━━━━━━━━┛
    EOF
);

# say @entities_advanced[0].wallet.perl;
# say "\n" x 3;
# say @entities_advanced[0].coa.wllt.perl;

# vim: ft=perl6
