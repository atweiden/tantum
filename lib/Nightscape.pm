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
        say "________________________________________________________________________________";
        say "[HEADER]";
        say $parsed.made.list[0]<journals>.pairs[2].value<journal><entries>.values[0]<entry><header>.perl;
        say "";
        say "[POSTINGS]";
        say $parsed.made.list[0]<journals>.pairs[2].value<journal><entries>.values[0]<entry><postings>.perl;
        say "________________________________________________________________________________";
        say "";
        say "________________________________________________________________________________";
        say "[HEADER]";
        say $parsed.made.list[0]<journals>.pairs[7].value<journal><entries>.values[0]<entry><header>.perl;
        say "";
        say "[POSTINGS]";
        say $parsed.made.list[0]<journals>.pairs[7].value<journal><entries>.values[0]<entry><postings>.perl;
        say "________________________________________________________________________________";
        say "";
        say "________________________________________________________________________________";
        say "[HEADER]";
        say $parsed.made.list[0]<journals>.pairs[9].value<journal><entries>.values[0]<entry><header>.perl;
        say "";
        say "[POSTINGS]";
        say $parsed.made.list[0]<journals>.pairs[9].value<journal><entries>.values[0]<entry><postings>.perl;
        say "________________________________________________________________________________";
        say "";
        say "________________________________________________________________________________";
        say "[HEADER]";
        say $parsed.made.list[0]<journals>.pairs[11].value<journal><entries>.values[0]<entry><header>.perl;
        say "";
        say "[POSTINGS]";
        say $parsed.made.list[0]<journals>.pairs[11].value<journal><entries>.values[0]<entry><postings>.perl;
        say "________________________________________________________________________________";
    }
}

# vim: ft=perl6
