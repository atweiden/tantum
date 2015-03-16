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

method transaction($/) {
    #if $<commodity_code> !eq $BASE_COMMODITY_CODE {
        # check for valid @ syntax || config option linked to valid price data for iso_date
    #}
}

# vim: ft=perl6
