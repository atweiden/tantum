use v6;
use Nightscape::Journal::Entry;
class Nightscape::Journal;

has Bool $.is_blank_line;
has Str $.comment_line;
has Nightscape::Journal::Entry $.entry;

# vim: ft=perl6
