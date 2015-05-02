use v6;
use Nightscape::Journal::Entry::Header;
use Nightscape::Journal::Entry::Posting;
class Nightscape::Journal::Entry;

has Nightscape::Journal::Entry::Header $.header;
has Nightscape::Journal::Entry::Posting @.postings;
has Str @.posting_comments;

# vim: ft=perl6
