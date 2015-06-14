use v6;
use lib 'lib';
use Test;
use Nightscape;
use Nightscape::Types;

plan 1;

my Str $file = "examples/sample.transactions";
my Nightscape::Entry @entries;

if $file.IO.e
{
    @entries = Nightscape.ls_entries(:$file);
}
else
{
    die "Sorry, couldn't locate file: $file";
}

{
    # get entries by entity Personal
    my Nightscape::Entry @entries_by_entity_personal = Nightscape.ls_entries(
        :@entries,
        :entity(/Personal/)
    );

    # get postings from entries by entity Personal
    my Nightscape::Entry::Posting @postings = Nightscape::Entry.ls_postings(
        :entries(@entries_by_entity_personal)
    );

    # filter postings by asset BTC, silo ASSETS
    my Regex $asset_code = /BTC/;
    my Silo $silo = ASSETS;
    my Nightscape::Entry::Posting @postings_btc_assets =
        Nightscape::Entry.ls_postings(:@postings, :$asset_code, :$silo);

    # check that two postings are returned for asset BTC, silo ASSETS
    is(
        @postings_btc_assets.elems,
        2,
        q:to/EOF/
        ♪ [ls_postings] - 1 of 1
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Passed argument of BTC:ASSETS returns 2 postings,
        ┃   Success   ┃    as expected.
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

# vim: ft=perl6
