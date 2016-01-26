use v6;
use lib 'lib';
use Test;
use Nightscape;
use Nightscape::Config;
use Nightscape::Types;

plan 2;

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

my Str $file = "t/data/sensible.txn";
my Nightscape::Entity @entities;
my Nightscape::Entry @entries;

if $file.IO.e
{
    @entries = Nightscape.ls-entries(:$file, :sort);
}
else
{
    die "Sorry, couldn't locate file: $file";
}

{
    # list unique entity names
    my VarName @entity-names = Nightscape.ls-entity-names(:@entries);
    for @entity-names -> $entity-name
    {
        # get entries by Entity
        my Nightscape::Entry @entries-entity = Nightscape.ls-entries(
            :@entries,
            :entity(/$entity-name/)
        );

        # instantiate Entity
        my Nightscape::Entity $entity .= new(
            :$entity-name,
            :entries(@entries-entity)
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
        # say 'Assets.USD: USD ', $entity.wallet{ASSETS}.get-balance(
        #     :asset-code("USD"),
        #     :recursive
        # );
        # say 'Assets.LTC: USD ', $entity.wallet{ASSETS}.get-balance(
        #     :asset-code("LTC"),
        #     :base-currency("USD"),
        #     :recursive
        # ), ' 「LTC ', $entity.wallet{ASSETS}.get-balance(
        #     :asset-code("LTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Income]';
        # say 'Income.USD: USD ', $entity.wallet{INCOME}.get-balance(
        #     :asset-code("USD"),
        #     :recursive
        # );
        # say 'Income.LTC: USD ', $entity.wallet{INCOME}.get-balance(
        #     :asset-code("LTC"),
        #     :base-currency("USD"),
        #     :recursive
        # ), ' 「LTC ', $entity.wallet{INCOME}.get-balance(
        #     :asset-code("LTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Equity]';
        # say 'Equity.USD: USD ', $entity.wallet{EQUITY}.get-balance(
        #     :asset-code("USD"),
        #     :recursive
        # );
        # say 'Equity.LTC: USD ', $entity.wallet{EQUITY}.get-balance(
        #     :asset-code("LTC"),
        #     :base-currency("USD"),
        #     :recursive
        # ), ' 「LTC ', $entity.wallet{EQUITY}.get-balance(
        #     :asset-code("LTC"),
        #     :recursive
        # ), '」';

        # say "\n" x 3;
        # say '[Assets]';
        # say 'Assets.USD: USD ', $entity.coa.wllt{ASSETS}.get-balance(
        #     :asset-code("USD"),
        #     :recursive
        # );
        # say 'Assets.LTC: USD ', $entity.coa.wllt{ASSETS}.get-balance(
        #     :asset-code("LTC"),
        #     :base-currency("USD"),
        #     :recursive
        # ), ' 「LTC ', $entity.coa.wllt{ASSETS}.get-balance(
        #     :asset-code("LTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Income]';
        # say 'Income.USD: USD ', $entity.coa.wllt{INCOME}.get-balance(
        #     :asset-code("USD"),
        #     :recursive
        # );
        # say 'Income.LTC: USD ', $entity.coa.wllt{INCOME}.get-balance(
        #     :asset-code("LTC"),
        #     :base-currency("USD"),
        #     :recursive
        # ), ' 「LTC ', $entity.coa.wllt{INCOME}.get-balance(
        #     :asset-code("LTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Equity]';
        # say 'Equity.USD: USD ', $entity.coa.wllt{EQUITY}.get-balance(
        #     :asset-code("USD"),
        #     :recursive
        # );
        # say 'Equity.LTC: USD ', $entity.coa.wllt{EQUITY}.get-balance(
        #     :asset-code("LTC"),
        #     :base-currency("USD"),
        #     :recursive
        # ), ' 「LTC ', $entity.coa.wllt{EQUITY}.get-balance(
        #     :asset-code("LTC"),
        #     :recursive
        # ), '」';
    }
}

# say "Entity: ", @entities[0].entity-name;
# say $_.perl for @entities[0].tree(:wallet(@entities[0].coa.wllt));

# if drift is negative, then INCOME + LIABILITIES + EQUITY outweighs
# ASSETS + EXPENSES, because INCOME, LIABILITIES and EQUITY have a
# -1 multiplier
my FatRat $drift = [+] (.drift for @entities[0].transactions);

my FatRat %balance{Silo} = @entities[0].get-eqbal(
    :wallet(@entities[0].coa.wllt)
    :acct(@entities[0].coa.acct)
);
# say "Entity.coa.wllt eqbal: ", %balance.perl;

# my FatRat %balance-orig{Silo} = @entities[0].get-eqbal(
#     :wallet(@entities[0].wallet)
# );
# say "Entity.wallet eqbal: ", %balance-orig.perl;

is(
    %balance{ASSETS} + %balance{EXPENSES},
    %balance{INCOME} + %balance{LIABILITIES} + %balance{EQUITY},
    q:to/EOF/
    ♪ [get-eqbal] - 1 of 2
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

my Str $file-advanced = "t/data/bad-form-multi-topic.txn";
my Nightscape::Entity @entities-advanced;
my Nightscape::Entry @entries-advanced;

if $file-advanced.IO.e
{
    @entries-advanced = Nightscape.ls-entries(:file($file-advanced), :sort);
}
else
{
    die "Sorry, couldn't locate file: $file-advanced";
}

{
    # list unique entity names
    my VarName @entity-names = Nightscape.ls-entity-names(
        :entries(@entries-advanced)
    );
    for @entity-names -> $entity-name
    {
        # get entries by Entity
        my Nightscape::Entry @entries-entity = Nightscape.ls-entries(
            :entries(@entries-advanced),
            :entity(/$entity-name/)
        );

        # instantiate Entity
        my Nightscape::Entity $entity .= new(
            :$entity-name,
            :entries(@entries-entity)
        );

        # instantiate transactions by Entity
        $entity.mktxn($_) for $entity.entries;

        # exec transactions by Entity
        $entity.transact($_) for $entity.transactions;

        # make chart of accounts for Entity
        $entity.mkcoa;

        # store entity
        push @entities-advanced, $entity;

        # say 'Entity.wallet';
        # say '[Assets]';
        # say 'Assets.USD: USD ', $entity.wallet{ASSETS}.get-balance(
        #     :asset-code("USD"),
        #     :recursive
        # );
        # say 'Assets.BTC: USD ', $entity.wallet{ASSETS}.get-balance(
        #     :asset-code("BTC"),
        #     :base-currency("USD"),
        #     :recursive
        # ), ' 「BTC ', $entity.wallet{ASSETS}.get-balance(
        #     :asset-code("BTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Income]';
        # say 'Income.USD: USD ', $entity.wallet{INCOME}.get-balance(
        #     :asset-code("USD"),
        #     :recursive
        # );
        # say 'Income.BTC: USD ', $entity.wallet{INCOME}.get-balance(
        #     :asset-code("BTC"),
        #     :base-currency("USD"),
        #     :recursive
        # ), ' 「BTC ', $entity.wallet{INCOME}.get-balance(
        #     :asset-code("BTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Equity]';
        # say 'Equity.USD: USD ', $entity.wallet{EQUITY}.get-balance(
        #     :asset-code("USD"),
        #     :recursive
        # );
        # say 'Equity.BTC: USD ', $entity.wallet{EQUITY}.get-balance(
        #     :asset-code("BTC"),
        #     :base-currency("USD"),
        #     :recursive
        # ), ' 「BTC ', $entity.wallet{EQUITY}.get-balance(
        #     :asset-code("BTC"),
        #     :recursive
        # ), '」';

        # say "\n" x 3;
        # say '[Assets]';
        # say 'Assets.USD: USD ', $entity.coa.wllt{ASSETS}.get-balance(
        #     :asset-code("USD"),
        #     :recursive
        # );
        # say 'Assets.BTC: USD ', $entity.coa.wllt{ASSETS}.get-balance(
        #     :asset-code("BTC"),
        #     :base-currency("USD"),
        #     :recursive
        # ), ' 「BTC ', $entity.coa.wllt{ASSETS}.get-balance(
        #     :asset-code("BTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Income]';
        # say 'Income.USD: USD ', $entity.coa.wllt{INCOME}.get-balance(
        #     :asset-code("USD"),
        #     :recursive
        # );
        # say 'Income.BTC: USD ', $entity.coa.wllt{INCOME}.get-balance(
        #     :asset-code("BTC"),
        #     :base-currency("USD"),
        #     :recursive
        # ), ' 「BTC ', $entity.coa.wllt{INCOME}.get-balance(
        #     :asset-code("BTC"),
        #     :recursive
        # ), '」';

        # say '';
        # say '[Equity]';
        # say 'Equity.USD: USD ', $entity.coa.wllt{EQUITY}.get-balance(
        #     :asset-code("USD"),
        #     :recursive
        # );
        # say 'Equity.BTC: USD ', $entity.coa.wllt{EQUITY}.get-balance(
        #     :asset-code("BTC"),
        #     :base-currency("USD"),
        #     :recursive
        # ), ' 「BTC ', $entity.coa.wllt{EQUITY}.get-balance(
        #     :asset-code("BTC"),
        #     :recursive
        # ), '」';
    }
}

# say $_.perl for @entities-advanced[0].tree(:wallet(@entities-advanced[0].coa.wllt));

my FatRat $drift-advanced = [+] (.drift for @entities-advanced[0].transactions);
my FatRat %balance-advanced{Silo} = @entities-advanced[0].get-eqbal(
    :wallet(@entities-advanced[0].coa.wllt)
    :acct(@entities-advanced[0].coa.acct)
);
# say "Entity.coa.wllt eqbal: ", %balance-advanced.perl;

# my FatRat %balance-advanced-orig{Silo} = @entities-advanced[0].get-eqbal(
#     :wallet(@entities-advanced[0].wallet)
# );
# say "Entity.wallet eqbal: ", %balance-advanced-orig.perl;

is(
    %balance-advanced{ASSETS} + %balance-advanced{EXPENSES},
    %balance-advanced{INCOME} + %balance-advanced{LIABILITIES}
        + %balance-advanced{EQUITY} + $drift-advanced,
    q:to/EOF/
    ♪ [get-eqbal] - 2 of 2
    ┏━━━━━━━━━━━━━┓
    ┃             ┃  ∙ Fundamental accounting equation balances,
    ┃   Success   ┃    as expected.
    ┃             ┃
    ┗━━━━━━━━━━━━━┛
    EOF
);

# say @entities-advanced[0].wallet.perl;
# say "\n" x 3;
# say @entities-advanced[0].coa.wllt.perl;

# vim: ft=perl6
