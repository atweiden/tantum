use v6;
use lib 'lib';
use Test;
use Nightscape;

plan 12;

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
    # check that the list of returned entries has only one entry on
    # date 2014-01-03, and that the returned entry's date is 2014-01-03
    my @entries_by_date = $nightscape.ls_entries(
        :entries($nightscape.entries),
        :date(Date.new("2014-01-03"))
    );
    is(
        @entries_by_date.elems,
        1,
        q:to/EOF/
        ♪ [ls_entries] - 1 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(Date.new("2014-01-03"))
        ┃   Success   ┃    returns 1 entry, as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
    is(
        @entries_by_date[0].header.date,
        Date.new("2014-01-03"),
        q:to/EOF/
        ♪ [ls_entries] - 2 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(Date.new("2014-01-03"))
        ┃   Success   ┃    returns entries with entry header date of
        ┃             ┃    Date.new("2014-01-03"), as expected.
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

{
    # check that the list of returned entries has 0 entries by entity
    # Lorem
    my @entries_by_entity_lorem = $nightscape.ls_entries(
        :entries($nightscape.entries),
        :entity(/Lorem/)
    );
    is(
        @entries_by_entity_lorem.elems,
        0,
        q:to/EOF/
        ♪ [ls_entries] - 3 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :entity(/Lorem/) returns 0
        ┃   Success   ┃    entries, as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

{
    # check that the list of returned entries has 7 entries by entity
    # Personal
    my @entries_by_entity_personal = $nightscape.ls_entries(
        :entries($nightscape.entries),
        :entity(/Personal/)
    );
    is(
        @entries_by_entity_personal.elems,
        7,
        q:to/EOF/
        ♪ [ls_entries] - 4 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :entity(/Personal/) returns 7
        ┃   Success   ┃    entries, as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

my Str $file_includes = "t/data/with-includes.transactions";

my Nightscape $nightscape_inc = Nightscape.new(
    conf => Nightscape::Config.new(
        base_currency => "USD"
    )
);

if $file_includes.IO.e
{
    $nightscape_inc.entries = $nightscape_inc.ls_entries(:file($file_includes));
}
else
{
    die "Sorry, couldn't locate transaction journal at 「$file_includes」";
}

{
    # check that the list of returned entries has only one entry on
    # date 2011-01-01, and that the returned entry's date is 2011-01-01
    my @entries_by_date = $nightscape_inc.ls_entries(
        :entries($nightscape_inc.entries),
        :date(Date.new("2011-01-01"))
    );
    is(
        @entries_by_date.elems,
        1,
        q:to/EOF/
        ♪ [ls_entries w/ includes] - 5 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(Date.new("2011-01-01"))
        ┃   Success   ┃    returns 1 entry, as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
    is(
        @entries_by_date[0].header.date,
        Date.new("2011-01-01"),
        q:to/EOF/
        ♪ [ls_entries w/ includes] - 6 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(Date.new("2011-01-01"))
        ┃   Success   ┃    returns entries with entry header date of
        ┃             ┃    Date.new("2011-01-01"), as expected.
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

{
    # check that the list of returned entries has only one entry on
    # date 2012-01-01, and that the returned entry's date is 2012-01-01
    my @entries_by_date = $nightscape_inc.ls_entries(
        :entries($nightscape_inc.entries),
        :date(Date.new("2012-01-01"))
    );
    is(
        @entries_by_date.elems,
        1,
        q:to/EOF/
        ♪ [ls_entries w/ includes] - 7 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(Date.new("2012-01-01"))
        ┃   Success   ┃    returns 1 entry, as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
    is(
        @entries_by_date[0].header.date,
        Date.new("2012-01-01"),
        q:to/EOF/
        ♪ [ls_entries w/ includes] - 8 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(Date.new("2012-01-01"))
        ┃   Success   ┃    returns entries with entry header date of
        ┃             ┃    Date.new("2012-01-01"), as expected.
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

{
    # check that the list of returned entries has only one entry on
    # date 2013-01-01, and that the returned entry's date is 2013-01-01
    my @entries_by_date = $nightscape_inc.ls_entries(
        :entries($nightscape_inc.entries),
        :date(Date.new("2013-01-01"))
    );
    is(
        @entries_by_date.elems,
        1,
        q:to/EOF/
        ♪ [ls_entries w/ includes] - 9 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(Date.new("2013-01-01"))
        ┃   Success   ┃    returns 1 entry, as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
    is(
        @entries_by_date[0].header.date,
        Date.new("2013-01-01"),
        q:to/EOF/
        ♪ [ls_entries w/ includes] - 10 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(Date.new("2013-01-01"))
        ┃   Success   ┃    returns entries with entry header date of
        ┃             ┃    Date.new("2013-01-01"), as expected.
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

{
    # check that the list of returned entries has only one entry on
    # date 2014-01-01, and that the returned entry's date is 2014-01-01
    my @entries_by_date = $nightscape_inc.ls_entries(
        :entries($nightscape_inc.entries),
        :date(Date.new("2014-01-01"))
    );
    is(
        @entries_by_date.elems,
        1,
        q:to/EOF/
        ♪ [ls_entries w/ includes] - 11 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(Date.new("2014-01-01"))
        ┃   Success   ┃    returns 1 entry, as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
    is(
        @entries_by_date[0].header.date,
        Date.new("2014-01-01"),
        q:to/EOF/
        ♪ [ls_entries w/ includes] - 12 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(Date.new("2014-01-01"))
        ┃   Success   ┃    returns entries with entry header date of
        ┃             ┃    Date.new("2014-01-01"), as expected.
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

# vim: ft=perl6
