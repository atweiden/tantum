use v6;
use Nightscape::Parser;
class Nightscape;

method it($file) {
    say %Config::CONFIG.perl;
    my $content = slurp $file;
    if my $parsed = Nightscape::Parser.parse($content) {
        for $parsed<journal>.list -> $journal {
            for $journal<entry>.kv -> $key, $value {
                given $key {
                    when /header/ {
                        say "------------------------------------------------------";
                        for $value.list -> $header {
                            say "Date: ", $header<iso_date>;
                            say "Description: ", $header<description> if $header<description>;
                        }
                    }
                    when /posting/ {
                        for $value.list -> $posting {
                            say "Account: ", $posting<account> if $posting<account>;
                            say "Transaction: ", $posting<transaction> if $posting<transaction>;
                        }
                        say "------------------------------------------------------";
                    }
                }
            }
        }
    }
}

# vim: ft=perl6
