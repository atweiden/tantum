use v6;
use lib 'lib';
use Test;
use Nightscape;

plan 3;

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
    for $nightscape.conf.ls_entities(%toml).kv -> $name, $rest
    {
        $nightscape.conf.entities{$name} = $rest;
    }

    # populate currencies
    $nightscape.conf.base_currency = %toml<base-currency>
        or die "Sorry, could not find global base-currency",
            " in config (mandatory).";
    for $nightscape.conf.ls_currencies(%toml).kv -> $code, $prices
    {
        $nightscape.conf.currencies{$code} =
            $nightscape.conf.gen_pricesheet(prices => $prices<Prices>);
    }
}

if $file.IO.e
{
    $nightscape.txjournal = $nightscape.gen_txjournal($file);
}
else
{
    die "Sorry, couldn't locate file: $file";
}

{
    # check that the list of returned entries has only one entry on
    # date 2014-01-03, and that the returned entry's date is 2014-01-03
    my @entries_by_date = Nightscape.ls_entries(
        :txjournal($nightscape.txjournal),
        :date(Date.new("2014-01-03"))
    );
    is(
        @entries_by_date.elems,
        1,
        q:to/EOF/
        ♪ [ls_entries] - 1 of 4
        Passed argument of :date(Date.new("2014-01-03")) returns 1 entry,
        as expected.
        EOF
    );
    is(
        @entries_by_date[0].entry.header.date,
        Date.new("2014-01-03"),
        q:to/EOF/
        ♪ [ls_entries] - 2 of 4
        Passed argument of :date(Date.new("2014-01-03")) returns entries
        with entry header date of Date.new(2014-01-03), as expected.
        EOF
    );
}

{
    # check that the list of returned entries has 0 entries by entity
    # Lorem
    my @entries_by_entity_lorem = Nightscape.ls_entries(
        :txjournal($nightscape.txjournal),
        :entity(/Lorem/)
    );
    is(
        @entries_by_entity_lorem.elems,
        0,
        q:to/EOF/
        ♪ [ls_entries] - 3 of 4
        Passed argument of :entity(/Lorem/) returns 0 entries, as
        expected.
        EOF
    );
}

{
    # check that the list of returned entries has 7 entries by entity
    # Personal
    # my @entries_by_entity_personal = Nightscape.ls_entries(
    #     :txjournal($nightscape.txjournal),
    #     :entity(/Personal/)
    # );
    # is(
    #     @entries_by_entity_personal.elems,
    #     7,
    #     q:to/EOF/
    #     ♪ [ls_entries] - 4 of 4
    #     Passed argument of :entity(/Personal/) returns 7 entries,
    #     as expected.
    #     EOF
    # );
}

# vim: ft=perl6
