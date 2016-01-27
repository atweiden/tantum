use v6;
use Nightscape::Entry;
use Nightscape::Import;
use Nightscape::Types;
unit class Nightscape::Import::TXN is Nightscape::Import;

method entries(Str:D :$txn!) returns Array #Array[Nightscape::Entry:D]
{
    use TXN;
    my Nightscape::Entry:D @entries = self.gen-entries(from-txn($txn).Array);
}

# vim: ft=perl6
