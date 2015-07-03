use v6;
use Nightscape::Parser::Actions;
use Nightscape::Parser::Grammar;
unit class Nightscape::Parser;

method parse($content) returns Match
{
    my Nightscape::Parser::Actions $actions .= new;
    Nightscape::Parser::Grammar.parse($content, :$actions);
}

# vim: ft=perl6
