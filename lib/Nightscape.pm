use v6;
use Nightscape::Config;
use Nightscape::Entity;
use Nightscape::Entry;
use Nightscape::Specs;
class Nightscape;

# config options, extracted from on disk conf and cmdline flags
has Nightscape::Config $.conf is rw;

# entries, extracted from on disk transaction journal
has Nightscape::Entry @.entries is rw;

# entities, indexed by name
has Nightscape::Entity %.entities{VarName} is rw;

# list entries from on disk transaction journal
multi method ls_entries(
    Str :$file!,
    Bool :$sort
) returns Array[Nightscape::Entry]
{
    use Nightscape::Parser;
    if my $parsed = Nightscape::Parser.parse(slurp($file), self.conf)
    {
        # entries, unsorted
        my Nightscape::Entry @entries = $parsed.made.grep({ .defined });

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

# vim: ft=perl6
