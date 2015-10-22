use v6;
use Nightscape::Types;
unit class Nightscape::Entry::Header;

has DateTime $.date;
has Str $.description;
has Int $.important;
has VarName @.tags;

# vim: ft=perl6
