use v6;
use lib 'lib';
use Test;
use Nightscape;
use Nightscape::Entity;
use Nightscape::Types;

plan 2;

my Str $file = "examples/sample.transactions";

my Nightscape $nightscape = Nightscape.new(
    conf => Nightscape::Config.new(
        base_currency => "USD"
    )
);

# prepare entities and currencies for transaction journal parsing
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

    # populate entities
    for $nightscape.conf.detoml_entities(%toml).kv -> $name, $rest
    {
        $nightscape.conf.entities{$name} = $rest;
    }

    # populate currencies
    $nightscape.conf.base_currency = %toml<base-currency>
        or die "Sorry, could not find global base-currency",
            " in config (mandatory).";
    for $nightscape.conf.detoml_currencies(%toml).kv -> $code, $prices
    {
        $nightscape.conf.currencies{$code} =
            $nightscape.conf.gen_pricesheet(prices => $prices<Prices>);
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

    # do postings for entity Personal
    for @entries_by_entity_personal -> $entry
    {
        $entity_personal.do(:posting($_)) for $entry.postings;

        # is entry balanced?
        # errors out on rakudo 2015.04
        # p6 t/05-entity-wallet-getbalance.t
        # 1..2
        # Invocant requires a 'Quantity' instance, but a type object
        # was passed. Did you forget a .new?
        #   in sub infix:<*> at src/gen/m-CORE.setting:13754
        #   in method is_balanced at lib/Nightscape/Entry.pm:55
        #   in block  at t/05-entity-wallet-getbalance.t:76
        #   in block <unit> at t/05-entity-wallet-getbalance.t:62
        #
        # # Looks like you planned 2 tests, but ran 0
        #
        # if $entry.is_balanced($nightscape.conf)
        # {
        #     # make debits / credits for each posting in entry
        #     $entity_personal.do(:posting($_)) for $entry.postings;
        # }
        # else
        # {
        #     die qq:to/EOF/;
        #     Sorry, given entry does not balance:
        #
        #     「$entry」
        #     EOF
        # }
    }

    # check that the balance of entity Personal's ASSETS is -837.84 USD
    is(
        $entity_personal.wallet{ASSETS}.getbalance("USD"),
        -837.84,
        q:to/EOF/
        ♪ [getbalance] - 1 of 2
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of "USD" returns -837.84,
        ┃   Success   ┃    as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );

    # check that the balance of entity Personal's ASSETS is 1.91111111 BTC
    is(
        $entity_personal.wallet{ASSETS}.getbalance("BTC"),
        1.91111111,
        q:to/EOF/
        ♪ [getbalance] - 2 of 2
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of "BTC" returns 1.91111111,
        ┃   Success   ┃    as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

# vim: ft=perl6
