use v6;
use Nightscape::Parser::Actions;
use Nightscape::Parser::Grammar;
class Nightscape::Parser;

method parse($content) {
    my $actions = Nightscape::Parser::Actions.new();
    my $match = Nightscape::Parser::Grammar.parse($content, :$actions);
    return $match;
}

# vim: ft=perl6
