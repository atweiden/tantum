use v6;
use Nightscape::Journal::Entry::Posting;
class Nightscape::Journal::Entry;

has Date $.date;
has $.description;
has @.tags;
has Nightscape::Journal::Entry::Posting @.postings;

# vim: ft=perl6
