use v6;
use Nightscape::Entity;
use Nightscape::Entry;
use Nightscape::Types;
unit class Nightscape;

# entities, indexed by name
# may include imported historical wallets and inventory with cost basis
has Nightscape::Entity %.entities{VarName};

# entries, extracted from on disk transaction journal
has Nightscape::Entry @.entries is rw;

# list unique entity names defined in entries
method ls-entity-names(
    Nightscape::Entry:D :@entries! is readonly
) returns Array[VarName:D]
{
    # to instantiate Nightscape::Entry, exec Nightscape.ls-entries(:$file)
    # to parse entries. Actions.pm contains logic barring more than one
    # entity per entry:
    #
    #     die unless @entities.grep(@entities[0]).elems == @entities.elems
    #
    # entries that include more than one entity violate syntax rules
    #
    # `.postings[0]` is allowable because we know only one entity can
    # appear in each entry
    my VarName:D @entities = (.postings[0].account.entity for @entries);
    @entities .= unique;
}

# list entries from on disk transaction journal
multi method ls-entries(
    Str:D :$file!,
    Bool :$sort
) returns Array[Nightscape::Entry]
{
    use TXN::Parser;

    # resolve include directives in transaction journal on disk
    my Str:D $journal = TXN::Parser.preprocess(:$file);

    # parse preprocessed transaction journal
    if my Match $parsed = TXN::Parser.parse($journal)
    {
        use Nightscape::Import;

        # entries, unsorted, with included transaction journals
        my Nightscape::Entry:D @entries =
            Nightscape::Import.entries($parsed.made);

        # entries, sorted by date ascending then by importance descending
        @entries = sort-entries(@entries) if $sort;

        @entries;
    }
    else
    {
        die "Sorry, could not parse transaction journal at 「$file」";
    }
}

# list entries from txnpkg txn.json
multi method ls-entries(
    Str:D :$json!,
    Bool :$sort
) returns Array[Nightscape::Entry:D]
{
    # import JSON cached txnpkg and convert to C<Nightscape::Entry>s
    use Nightscape::Import;
    my Nightscape::Entry:D @entries = Nightscape::Import.entries(:$json);

    # entries, sorted by date ascending then by importance descending
    @entries = sort-entries(@entries) if $sort;

    @entries;
}

# filter entries
multi method ls-entries(
    Nightscape::Entry:D :@entries is readonly = @.entries,
    DateTime :$date,
    Range :$date-range,
    Regex :$description,
    Regex :$entity,
    EntryID :$entry-id,
    Int :$important,
    Regex :$tag
) returns Array[Nightscape::Entry]
{
    my Nightscape::Entry @e = @entries;
    @e = self._ls-entries(:entries(@e), :$date) if $date;
    @e = self._ls-entries(:entries(@e), :$date-range) if $date-range;
    @e = self._ls-entries(:entries(@e), :$description) if defined $description;
    @e = self._ls-entries(:entries(@e), :$entity) if defined $entity;
    @e = self._ls-entries(:entries(@e), :$entry-id) if $entry-id;
    @e = self._ls-entries(:entries(@e), :$important) if $important;
    @e = self._ls-entries(:entries(@e), :$tag) if defined $tag;
    @e;
}

# list entries by date
multi method _ls-entries(
    Nightscape::Entry:D :@entries! is readonly,
    DateTime:D :$date!
) returns Array[Nightscape::Entry]
{
    my Nightscape::Entry @e = @entries.grep({ .header.date ~~ ~$date });
}

# list entries within date range
multi method _ls-entries(
    Nightscape::Entry:D :@entries! is readonly,
    Range:D :$date-range!
) returns Array[Nightscape::Entry]
{
    my Nightscape::Entry @e = @entries.grep({ .header.date ~~ $date-range });
}

# list entries by entity
multi method _ls-entries(
    Nightscape::Entry:D :@entries! is readonly,
    Regex:D :$entity!
) returns Array[Nightscape::Entry]
{
    my Nightscape::Entry @e = @entries.grep({
        .postings[0].account.entity ~~ $entity
    });
}

# list entries by EntryID
multi method _ls-entries(
    Nightscape::Entry:D :@entries! is readonly,
    EntryID:D :$entry-id!
) returns Array[Nightscape::Entry]
{
    my Nightscape::Entry @e = @entries.grep({ .id == $entry-id });
}

# instantiate entity
method mkentity(VarName:D :$entity-name!, Bool :$force)
{
    sub init()
    {
        # instantiate new entity
        %!entities{$entity-name} = Nightscape::Entity.new(:$entity-name);
    }

    # was :force arg passed?
    if $force
    {
        # overwrite existing entity with new entity
        init();
    }
    # does entity exist?
    elsif %.entities{$entity-name}
    {
        # error: entity exists, can't overwrite
        die "Sorry, can't mkentity 「$entity-name」: entity exists.";
    }
    else
    {
        # entity does not exist, instantiate new entity
        init();
    }
}

# sort entries by date ascending then by importance descending
sub sort-entries(Nightscape::Entry @entries) returns Array[Nightscape::Entry]
{
    my Nightscape::Entry @e = @entries.sort({
        $^b.header.important > $^a.header.important
    }).sort({
        .header.date
    });

    @e;
}

# vim: ft=perl6
