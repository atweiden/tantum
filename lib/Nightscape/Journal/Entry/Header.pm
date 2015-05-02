use v6;
use Nightscape::Specs;
class Nightscape::Journal::Entry::Header;

has Int $.id;
has Date $.date;
has Str $.description;
has Int $.important;
has VarName @.tags;
has Str $.eol_comment;

# vim: ft=perl6
