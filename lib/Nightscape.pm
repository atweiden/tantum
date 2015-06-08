use v6;
use Nightscape::Config;
use Nightscape::Entity;
use Nightscape::Entry;
use Nightscape::Types;
unit class Nightscape;

# config options, extracted from on disk conf and cmdline flags
has Nightscape::Config $.conf is rw;

# entities, indexed by name
has Nightscape::Entity %.entities{VarName} is rw;

# entries, extracted from on disk transaction journal
has Nightscape::Entry @.entries is rw;

# list entries from on disk transaction journal
multi method ls_entries(
    Str :$file!,
    Bool :$sort
) returns Array[Nightscape::Entry]
{
    use Nightscape::Parser;
    if my $parsed = Nightscape::Parser.parse(slurp($file))
    {
        my Nightscape::Entry @entries;
        my Nightscape::Entry @entries_included;

        # parse entries from included transaction journals
        push @entries_included, self.ls_entries( :file($_.filename) )
            for $parsed.made.grep(Nightscape::Parser::Include);

        # entries, unsorted, with included transaction journals
        @entries = ( $parsed.made.grep(Nightscape::Entry), @entries_included );

        # entries, sorted by date ascending then by importance descending
        @entries = @entries.sort({
            $^b.header.important > $^a.header.important
        }).sort({
            .header.date
        }) if $sort;

        @entries;
    }
    else
    {
        die "Sorry, could not parse transaction journal at 「$file」";
    }
}

# filter entries
multi method ls_entries(
    Nightscape::Entry :@entries!,
    Date :$date,
    Regex :$description,
    Regex :$entity,
    Int :$id,
    Int :$important,
    Regex :$tag
) returns Array[Nightscape::Entry]
{
    my Nightscape::Entry @e = @entries;
    @e = self._ls_entries(:entries(@e), :$date) if $date;
    @e = self._ls_entries(:entries(@e), :$description) if defined $description;
    @e = self._ls_entries(:entries(@e), :$entity) if defined $entity;
    @e = self._ls_entries(:entries(@e), :$id) if $id;
    @e = self._ls_entries(:entries(@e), :$important) if $important;
    @e = self._ls_entries(:entries(@e), :$tag) if defined $tag;
    @e;
}

# list entries by date
multi method _ls_entries(
    Nightscape::Entry :@entries!,
    Date :$date!
) returns Array[Nightscape::Entry]
{
    my Nightscape::Entry @e = @entries.grep({ .header.date ~~ $date });
}

# list entries by entity
multi method _ls_entries(
    Nightscape::Entry :@entries!,
    Regex :$entity!
) returns Array[Nightscape::Entry]
{
    my Nightscape::Entry @e =
        @entries.grep({ .postings[0].account.entity ~~ $entity });
}

# list postings from entries
multi method ls_postings(
    Nightscape::Entry :@entries!
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @postings;
    for @entries -> $entry
    {
        push @postings, $_ for $entry.postings;
    }
    @postings;
}

# filter postings
multi method ls_postings(
    Nightscape::Entry::Posting :@postings!,
    Regex :$asset_code,
    Silo :$silo
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @p = @postings;
    @p = self._ls_postings(:postings(@p), :$asset_code) if defined $asset_code;
    @p = self._ls_postings(:postings(@p), :$silo) if defined $silo;
    @p;
}

# list postings by asset code
multi method _ls_postings(
    Nightscape::Entry::Posting :@postings!,
    Regex :$asset_code!
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @p =
        @postings.grep({ .amount.asset_code ~~ $asset_code });
}

# list postings by silo
multi method _ls_postings(
    Nightscape::Entry::Posting :@postings!,
    Silo :$silo!
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @p =
        @postings.grep({ .account.silo ~~ $silo });
}

# vim: ft=perl6
