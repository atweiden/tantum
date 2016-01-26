use v6;
use lib 'lib';
use Test;
use Nightscape;

plan 12;

my Str $file = "examples/sample/sample.txn";
my Nightscape::Entry @entries;

if $file.IO.e
{
    @entries = Nightscape.ls-entries(:$file);
}
else
{
    die "Sorry, couldn't locate file: $file";
}

{
    # check that the list of returned entries has only one entry on
    # date 2014-01-03, and that the returned entry's date is 2014-01-03
    my Nightscape::Entry @entries-by-date = Nightscape.ls-entries(
        :@entries,
        :date(DateTime.new(:year(2014), :month(1), :day(3)))
    );
    is(
        @entries-by-date.elems,
        1,
        q:to/EOF/
        ♪ [ls-entries] - 1 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(DateTime.new(...))
        ┃   Success   ┃    returns 1 entry, as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
    is(
        @entries-by-date[0].header.date,
        DateTime.new(:year(2014), :month(1), :day(3)),
        q:to/EOF/
        ♪ [ls-entries] - 2 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(DateTime.new(...))
        ┃   Success   ┃    returns entries with entry header date of
        ┃             ┃    DateTime.new(...), as expected.
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

{
    # check that the list of returned entries has 0 entries by entity
    # Lorem
    my Nightscape::Entry @entries-by-entity-lorem = Nightscape.ls-entries(
        :@entries,
        :entity(/Lorem/)
    );
    is(
        @entries-by-entity-lorem.elems,
        0,
        q:to/EOF/
        ♪ [ls-entries] - 3 of 12
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
    my Nightscape::Entry @entries-by-entity-personal = Nightscape.ls-entries(
        :@entries,
        :entity(/Personal/)
    );
    is(
        @entries-by-entity-personal.elems,
        7,
        q:to/EOF/
        ♪ [ls-entries] - 4 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :entity(/Personal/) returns 7
        ┃   Success   ┃    entries, as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

my Str $file-inc = "t/data/with-includes.txn";
my Nightscape::Entry @entries-inc;

if $file-inc.IO.e
{
    @entries-inc = Nightscape.ls-entries(:file($file-inc));
}
else
{
    die "Sorry, couldn't locate transaction journal at 「$file-inc」";
}

{
    # check that the list of returned entries has only one entry on
    # date 2011-01-01, and that the returned entry's date is 2011-01-01
    my Nightscape::Entry @entries-by-date = Nightscape.ls-entries(
        :entries(@entries-inc),
        :date(DateTime.new(:year(2011), :month(1), :day(1)))
    );
    is(
        @entries-by-date.elems,
        1,
        q:to/EOF/
        ♪ [ls-entries w/ includes] - 5 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(DateTime.new(...))
        ┃   Success   ┃    returns 1 entry, as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
    is(
        @entries-by-date[0].header.date,
        DateTime.new(:year(2011), :month(1), :day(1)),
        q:to/EOF/
        ♪ [ls-entries w/ includes] - 6 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(DateTime.new(...))
        ┃   Success   ┃    returns entries with entry header date of
        ┃             ┃    DateTime.new(...), as expected.
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

{
    # check that the list of returned entries has only one entry on
    # date 2012-01-01, and that the returned entry's date is 2012-01-01
    my Nightscape::Entry @entries-by-date = Nightscape.ls-entries(
        :entries(@entries-inc),
        :date(DateTime.new(:year(2012), :month(1), :day(1)))
    );
    is(
        @entries-by-date.elems,
        1,
        q:to/EOF/
        ♪ [ls-entries w/ includes] - 7 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(DateTime.new(...))
        ┃   Success   ┃    returns 1 entry, as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
    is(
        @entries-by-date[0].header.date,
        DateTime.new(:year(2012), :month(1), :day(1)),
        q:to/EOF/
        ♪ [ls-entries w/ includes] - 8 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(DateTime.new(...))
        ┃   Success   ┃    returns entries with entry header date of
        ┃             ┃    DateTime.new(...), as expected.
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

{
    # check that the list of returned entries has only one entry on
    # date 2013-01-01, and that the returned entry's date is 2013-01-01
    my Nightscape::Entry @entries-by-date = Nightscape.ls-entries(
        :entries(@entries-inc),
        :date(DateTime.new(:year(2013), :month(1), :day(1)))
    );
    is(
        @entries-by-date.elems,
        1,
        q:to/EOF/
        ♪ [ls-entries w/ includes] - 9 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(DateTime.new(...))
        ┃   Success   ┃    returns 1 entry, as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
    is(
        @entries-by-date[0].header.date,
        DateTime.new(:year(2013), :month(1), :day(1)),
        q:to/EOF/
        ♪ [ls-entries w/ includes] - 10 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(DateTime.new(...))
        ┃   Success   ┃    returns entries with entry header date of
        ┃             ┃    DateTime.new(...), as expected.
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

{
    # check that the list of returned entries has only one entry on
    # date 2014-01-01, and that the returned entry's date is 2014-01-01
    my Nightscape::Entry @entries-by-date = Nightscape.ls-entries(
        :entries(@entries-inc),
        :date(DateTime.new(:year(2014), :month(1), :day(1)))
    );
    is(
        @entries-by-date.elems,
        1,
        q:to/EOF/
        ♪ [ls-entries w/ includes] - 11 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(DateTime.new(...))
        ┃   Success   ┃    returns 1 entry, as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
    is(
        @entries-by-date[0].header.date,
        DateTime.new(:year(2014), :month(1), :day(1)),
        q:to/EOF/
        ♪ [ls-entries w/ includes] - 12 of 12
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of :date(DateTime.new(...))
        ┃   Success   ┃    returns entries with entry header date of
        ┃             ┃    DateTime.new(...), as expected.
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

# vim: ft=perl6
