use v6;
use Nightscape::Journal::Entry::Posting::Account;
use Nightscape::Journal::Entry::Posting::Amount;
use Nightscape::Specs;
class Nightscape::Journal::Entry::Posting;

has Nightscape::Journal::Entry::Posting::Account $.account;
has Nightscape::Journal::Entry::Posting::Amount $.amount;
has DrCr $.drcr;

# vim: ft=perl6
