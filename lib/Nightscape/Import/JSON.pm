use v6;
use Nightscape::Entry;
use Nightscape::Import;
use Nightscape::Types;
unit class Nightscape::Import::JSON is Nightscape::Import;

method gen-datetime($dt) returns DateTime:D
{
    use TXN::Parser::Actions;
    use TXN::Parser::Grammar;
    my TXN::Parser::Actions $actions .= new;
    my DateTime:D $date = TXN::Parser::Grammar.parse(
        $dt,
        :$actions,
        :rule<date>
    ).made;
}

method entries(Str:D :$json!) returns Array #Array[Nightscape::Entry:D]
{
    use JSON::Tiny;
    my Nightscape::Entry:D @entries = self.gen-entries(from-json($json).Array);
}

# vim: ft=perl6
