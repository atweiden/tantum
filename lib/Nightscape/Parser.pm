use v6;
use Nightscape::Parser::Actions;
use Nightscape::Parser::Grammar;
class Nightscape::Parser;

method parse($content)
{
    my Nightscape::Parser::Actions $actions = Nightscape::Parser::Actions.new;
    Nightscape::Parser::Grammar.parse($content, :$actions);
}

# vim: ft=perl6
