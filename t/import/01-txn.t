use v6;
use lib 'lib';
use Test;
use Nightscape;

plan 2;

subtest
{
    my Str:D $txn = slurp 'examples/sample/sample.txn';
    my Nightscape::Entry:D @entries = Nightscape.ls-entries(:$txn);

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

subtest
{
    my Str:D $txn = slurp 't/data/with-includes.txn';
    my Nightscape::Entry:D @entries = Nightscape.ls-entries(:$txn);

    # check that the list of returned entries has only one entry on
    # date 2011-01-01, and that the returned entry's date is 2011-01-01
    my Nightscape::Entry @entries-by-date-a = Nightscape.ls-entries(
        :@entries,
        :date(DateTime.new(:year(2011), :month(1), :day(1)))
    );
    is(
        @entries-by-date-a.elems,
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
        @entries-by-date-a[0].header.date,
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

    # check that the list of returned entries has only one entry on
    # date 2012-01-01, and that the returned entry's date is 2012-01-01
    my Nightscape::Entry @entries-by-date-b = Nightscape.ls-entries(
        :@entries,
        :date(DateTime.new(:year(2012), :month(1), :day(1)))
    );

    is(
        @entries-by-date-b.elems,
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
        @entries-by-date-b[0].header.date,
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

    # check that the list of returned entries has only one entry on
    # date 2013-01-01, and that the returned entry's date is 2013-01-01
    my Nightscape::Entry @entries-by-date-c = Nightscape.ls-entries(
        :@entries,
        :date(DateTime.new(:year(2013), :month(1), :day(1)))
    );

    is(
        @entries-by-date-c.elems,
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
        @entries-by-date-c[0].header.date,
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

    # check that the list of returned entries has only one entry on
    # date 2014-01-01, and that the returned entry's date is 2014-01-01
    my Nightscape::Entry @entries-by-date-d = Nightscape.ls-entries(
        :@entries,
        :date(DateTime.new(:year(2014), :month(1), :day(1)))
    );

    is(
        @entries-by-date-d.elems,
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
        @entries-by-date-d[0].header.date,
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
