use v6;
use Nightscape::Types;
class Nightscape::Entry::Header;

has Int $.id;
has Date $.date;
has Str $.description;
has Int $.important;
has VarName @.tags;
has Str $.eol_comment;

# vim: ft=perl6
