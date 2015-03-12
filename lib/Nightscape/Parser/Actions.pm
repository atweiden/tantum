use v6;
class Nightscape::Parser::Actions;

method iso_date($/) {
    try {
        my $valid_date = Date.new("$/");

        CATCH {
            say "Sorry, invalid date";
        }
    }
}

# vim: ft=perl6
