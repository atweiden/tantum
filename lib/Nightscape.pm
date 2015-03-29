use v6;
use Nightscape::Parser;
class Nightscape;

method it($file) {
    say "________________________________________________________________________________";
    say "[CONFIG]";
    say %Config::CONFIG.perl;
    say "________________________________________________________________________________";
    my $content = slurp $file;
    if my $parsed = Nightscape::Parser.parse($content) {
        for $parsed.made.list -> $journal {
            for $journal.kv -> $key, $value {
                unless $key ~~ / blank_line || comment_line / {
                    say "[HEADER]" if $value.key ~~ /header/;
                    say "[POSTINGS]" if $value.key ~~ /postings/;
                    say $value.key.perl, " => ", $value.value.perl, "\n";
                }
            }
        };
    }
}

# vim: ft=perl6
