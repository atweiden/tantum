use v6;
use Nightscape::Parser;
class Nightscape;

method it($file, %config) {
    say %config.perl;
    my $content = slurp $file;
    if my $parsed = Nightscape::Parser.parse($content) {
        for $parsed<journal>.list -> $journal {
            for $journal<entry>.list -> $entry {
                say "------------------------------------------------------";
                for $entry<header>.list -> $header {
                    say "Date: ", $header<iso_date>;
                    say "Description: ", $header<description> if $header<description>;
                }
                for $entry<posting>.list -> $posting {
                    say "Account: ", $posting<account> if $posting<account>;
                    say "Transaction: ", $posting<transaction> if $posting<transaction>;
                }
                say "------------------------------------------------------";
            }
        }
    }
}

# vim: ft=perl6
