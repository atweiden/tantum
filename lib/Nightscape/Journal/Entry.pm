use v6;
use Nightscape::Journal::Entry::Posting;
class Nightscape::Journal::Entry;

has $.id;
has Date $.date;
has $.description;
has @.groups;
has @.tags;
has Nightscape::Journal::Entry::Posting @.postings;

# vim: ft=perl6