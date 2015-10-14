use v6;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entry::Header;

has Int $.id;
has UUID $.uuid;
has DateTime $.date;
has Str $.description;
has Int $.important;
has VarName @.tags;
has Str $.eol_comment;

# vim: ft=perl6
