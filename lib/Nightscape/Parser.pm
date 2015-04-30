use v6;
use Nightscape::Parser::Actions;
use Nightscape::Parser::Grammar;
class Nightscape::Parser;

method parse($content, $conf)
{
    my $actions = Nightscape::Parser::Actions.new(:$conf);
    Nightscape::Parser::Grammar.parse($content, :$actions);
}

# vim: ft=perl6
