use v6;
use Nightscape::Entry::Header;
use Nightscape::Entry::Posting;
class Nightscape::Entry;

has Nightscape::Entry::Header $.header;
has Nightscape::Entry::Posting @.postings;
has Str @.posting_comments;

# vim: ft=perl6
