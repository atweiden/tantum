use v6;
use Nightscape::Specs;
class Nightscape::Journal::Entry::Posting::Account;

has Silo $.silo;
has VarName $.entity;
has VarName @.subaccount;

# vim: ft=perl6
