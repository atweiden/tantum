use v6;
use lib 'lib';
use Test;
use Nightscape;
use Nightscape::Types;

plan 1;

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
    # get entries by entity Personal
    my Nightscape::Entry @entries-by-entity-personal = Nightscape.ls-entries(
        :@entries,
        :entity(/Personal/)
    );

    # get postings from entries by entity Personal
    my Nightscape::Entry::Posting @postings = Nightscape::Entry.ls-postings(
        :entries(@entries-by-entity-personal)
    );

    # filter postings by asset BTC, silo ASSETS
    my Regex $asset-code = /BTC/;
    my Silo $silo = ASSETS;
    my Nightscape::Entry::Posting @postings-btc-assets =
        Nightscape::Entry.ls-postings(:@postings, :$asset-code, :$silo);

    # check that two postings are returned for asset BTC, silo ASSETS
    is(
        @postings-btc-assets.elems,
        2,
        q:to/EOF/
        ♪ [ls-postings] - 1 of 1
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of BTC:ASSETS returns 2 postings,
        ┃   Success   ┃    as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

# vim: ft=perl6
