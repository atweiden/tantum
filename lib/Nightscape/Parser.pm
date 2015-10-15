use v6;
use Nightscape::Parser::Actions;
use Nightscape::Parser::Grammar;
unit class Nightscape::Parser;

method parse(Str:D $journal, *%opts) returns Match
{
    my Nightscape::Parser::Actions $actions .= new;
    Nightscape::Parser::Grammar.parse($journal, :$actions, |%opts);
}

method preprocess(Str:D $file) returns Str:D
{
    self!resolve_includes(slurp $file);
}

method !resolve_includes(Str:D $journal_orig) returns Str:D
{
    my Str:D $journal = "";
    for $journal_orig.lines -> $line
    {
        $journal ~= Nightscape::Parser::Grammar.parse(
            "$line\n",
            :actions(Nightscape::Parser::Actions),
            :rule<include_line>
        ) ?? self.preprocess($/.made) !! $line ~ "\n";
    }
    $journal;
}

# vim: ft=perl6
