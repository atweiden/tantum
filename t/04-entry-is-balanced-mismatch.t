use v6;
use lib 'lib';
use Test;
use Nightscape;

plan 2;

my Str $file = "t/data/invalid.txn";
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
    # make entity Personal
    my Nightscape::Entity $entity-personal .= new(:entity-name("Personal"));

    # get entries by entity Personal
    my Nightscape::Entry @entries-by-entity-personal = Nightscape.ls-entries(
        :@entries,
        :entity(/Personal/)
    );

    # check that entry id 3 of data/invalid.txn causes exchange rate
    # mismatch error
    dies-ok { @entries-by-entity-personal[3].is-balanced },
            q:to/EOF/;
            ♪ [is-balanced-mismatch] - 1 of 2
            ┏━━━━━━━━━━━━━┓
            ┃             ┃  ∙ Passed argument of @entries-by-entity-personal[3]
            ┃   Success   ┃    causes exchange rate mismatch error, as expected.
            ┃             ┃
            ┗━━━━━━━━━━━━━┛
            EOF

    # check that entry id 4 of data/invalid.txn causes exchange rate
    # mismatch error
    dies-ok { @entries-by-entity-personal[4].is-balanced },
            q:to/EOF/;
            ♪ [is-balanced-mismatch] - 2 of 2
            ┏━━━━━━━━━━━━━┓
            ┃             ┃  ∙ Passed argument of @entries-by-entity-personal[4]
            ┃   Success   ┃    causes exchange rate mismatch error, as expected.
            ┃             ┃
            ┗━━━━━━━━━━━━━┛
            EOF
}

# vim: ft=perl6
