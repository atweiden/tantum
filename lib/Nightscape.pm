use v6;
use Nightscape::Config;
use Nightscape::Journal;
class Nightscape;

has Nightscape::Config $.conf is rw;
has Nightscape::Journal @.txjournal is rw;

method gen_conf(%conf?) returns Nightscape::Config
{
    Nightscape::Config.new(|%conf);
}

method gen_txjournal(Str $file) returns Array[Nightscape::Journal]
{
    use Nightscape::Parser;
    if my $parsed = Nightscape::Parser.parse(slurp($file), self.conf)
    {
        # return entries, sorted by date ascending then by importance descending
        my Nightscape::Journal @txjournal = $parsed.made.grep({
            .entry
        }).sort({
            $^b.entry.header.important > $^a.entry.header.important
        }).sort({
            .entry.header.date
        });
    }
    else
    {
        die "Sorry, could not parse transaction journal at 「$file」";
    }
}

# list entries from txjournal, with optional filters
multi method ls_entries(
    Nightscape::Journal :@txjournal!,
    Date :$date,
    Str :$description,
    Str :$entity,
    Int :$id,
    Int :$important,
    Str :$tag
) returns Array[Nightscape::Journal]
{
    my Nightscape::Journal @entries = @txjournal;

    # by date
    @entries =
        self._ls_entries(:txjournal(@entries), :$date)
            if $date;

    # by description
    @entries =
        self._ls_entries(:txjournal(@entries), :$description)
            if $description;

    # by entity
    @entries =
        self._ls_entries(:txjournal(@entries), :$entity)
            if $entity;

    # by id
    @entries =
        self._ls_entries(:txjournal(@entries), :$id)
            if $id;

    # by important
    @entries =
        self._ls_entries(:txjournal(@entries), :$important)
            if $important;

    # by tag
    @entries =
        self._ls_entries(:txjournal(@entries), :$tag)
            if $tag;

    @entries;
}

# list entries by date
multi submethod _ls_entries(
    Nightscape::Journal :@txjournal!,
    Date :$date!
) returns Array[Nightscape::Journal]
{
    my Nightscape::Journal @entries = @txjournal.grep({
        .entry.header.date ~~ $date
    });
    @entries;
}

# list entries by entity
multi submethod _ls_entries(
    Nightscape::Journal :@txjournal!,
    Str :$entity!
) returns Array[Nightscape::Journal]
{
    my Nightscape::Journal @entries =
        @txjournal.grep({
            .entry.postings[0].account.entity ~~ $entity
        });
    @entries;
}

# vim: ft=perl6
