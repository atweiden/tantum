use v6;

grammar Nightscape {
    # When parsing file formats where some whitespace (for example
    # vertical whitespace) is significant, it is advisable to override ws:
    token ws {
        <!ww>   # only match when not within a word
        \h*     # only match horizontal whitespace
    }

    my token year {
        \d ** 4
    }

    my token month {
        [ 0 <[1..9]> ] ** 1 || [ 1 <[0..2]> ] ** 1
    }

    my token day {
        [ <[0..2]> \d ] ** 1 || [ 3 <[0..1]> ] ** 1
    }

    my token iso_date {
        [ <year> ** 1 '-' <month> ** 1 '-' <day> ** 1 ] ** 1
    }

    my token description {
        \N*
    }

    my token header {
        <iso_date> ** 1
        [
            \h+
            <description> ** 1
        ]?
    }

    my token account_main {
        [ :i
          Asset[s]?
        | Expense[s]?
        | Income | Revenue[s]?
        | Liabilit[y|ies]
        | Equit[y|ies]
        ] ** 1
    }

    my token account_sub {
        <[\w\d\.\-,'“”‘’]>+
    }

    my token account {
        [ <account_main> ** 1 [':'+ <account_sub>]* ] ** 1
    }

    my token commodity_minus {
        '-'
    }

    my token commodity_symbol {
        \D+
    }

    my token commodity_code {
        <:Letter>+
    }

    my token commodity_quantity {
        [ \d+ ]?
        [ '.' ]?
        \d+
    }

    my token transaction {
        <commodity_minus>? <commodity_symbol>? \h* <commodity_quantity> \h+ <commodity_code>       # -$100.00 USD
        || <commodity_symbol>? \h* <commodity_minus>? <commodity_quantity> \h+ <commodity_code>    # $-100.00 USD
        || <commodity_code> \h+ <commodity_minus>? <commodity_quantity>                            # USD -100.00
    }

    my token posting {
        <account> ** 1
        \h+
        <transaction> ** 1
    }

    my token entry {
        [ ^^ <header> \n ] ** 1
        [
            \h ** 2..*
            <posting>
            \n
        ]+
    }

    token TOP {
        [
            <entry>
            \s*
        ]*
    }

}

my $content_tx = q:to/EOTX/;
2014-01-01 I started the year with $1000 in Bankwest cheque account
  Assets:Personal:Bankwest:Cheque    $1000.00 USD
  Equity:Personal                    $1000.00 USD

2014-01-02 I paid Exxon Mobile $10 for gas from Bankwest cheque account
  Expenses:Personal:Fuel             $10.00 USD
  Assets:Personal:Bankwest:Cheque   -$10.00 USD

2014-01-02
  Expenses:Personal:Fuel             $20.00 USD
  Assets:Personal:Bankwest:Cheque   -$20.00 USD
EOTX

class Nightscape::Actions {
    method TOP($/) {
        # supersede $/ = $/.trim-leading.trim-trailing;
    }
}
my $actions = Nightscape::Actions.new;

say so Nightscape.parse("$content_tx");
my $tx = Nightscape.parse("$content_tx", actions => $actions);
say $tx;

say "\n";
say "---------------------------------------------------------------------------\n" x 8;

if Nightscape.parse("$content_tx", actions => $actions) {
    my Int $count = 0;
    for $<entry>.list -> $entry {

        say "";
        say "\" [Entry $count] --- \{\{\{";
        say "";

        for $entry<header>.list -> $header {
            say "Date: ", $header<iso_date>;
            say "Description: ", $header<description>;
        }

        for $entry<posting>.list -> $posting {
            say "Account: ", $posting<account>;
            say "Transaction: ", $posting<transaction>;
        }

        say "";
        say "\" --- end [Entry $count] }}}";
        $count++;
    }
}

# vim: ft=perl6
