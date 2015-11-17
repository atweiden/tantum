use v6;
use Nightscape::Types;
unit class Nightscape::Entry::Posting::Account;

has Silo $.silo is required;
has VarName $.entity is required;
has VarName @.subaccount;

# vim: ft=perl6
