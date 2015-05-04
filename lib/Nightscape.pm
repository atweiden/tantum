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

# vim: ft=perl6
