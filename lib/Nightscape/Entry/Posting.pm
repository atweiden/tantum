use v6;
use Nightscape::Entry::Posting::Account;
use Nightscape::Entry::Posting::Amount;
use Nightscape::Specs;
class Nightscape::Entry::Posting;

has Nightscape::Entry::Posting::Account $.account;
has Nightscape::Entry::Posting::Amount $.amount;
has DrCr $.drcr;

# vim: ft=perl6
