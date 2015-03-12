use v6;
grammar Nightscape::Parser::Grammar;

token ws {
    # When parsing file formats where some whitespace (for example
    # vertical whitespace) is significant, it is advisable to
    # override ws:
    <!ww>    # only match when not within a word
    \h*      # only match horizontal whitespace
}

token comment {
    '#' \N*
}

token year {
    \d ** 4
}

token month {
    0 <[1..9]> || 1 <[0..2]>
}

token day {
    <[0..2]> \d || 3 <[0..1]>
}

token iso_date {
    [ <year> ** 1 '-' <month> ** 1 '-' <day> ** 1 ] ** 1
}

token description {
    '"'
    <-["\\]>*
    [ \\ . <-["\\]>* ]*
    '"'
}

token header {
    <iso_date> ** 1
    [ \h+ <description> ** 1 ]?
    [ \h+ <comment> ]?
}

token account_main {
    [ :i
        Asset[s]?
    | Expense[s]?
    | Income | Revenue[s]?
    | Liabilit[y|ies]
    | Equit[y|ies]
    ] ** 1
}

token account_sub {
    <[\w\d\.\-]>+
}

token account {
    [ <account_main> ** 1 [':' + <account_sub>]* ] ** 1
}

token commodity_minus {
    '-'
}

token commodity_symbol {
    \D+
}

token commodity_code {
    <:Letter>+
}

token commodity_quantity {
    \d+ [ '.' \d+ ]?
    || '.' \d+
}

token transaction {
    <commodity_minus>? <commodity_symbol>? \h* <commodity_quantity> \h+ <commodity_code>       # -$100.00 USD
    || <commodity_symbol>? \h* <commodity_minus>? <commodity_quantity> \h+ <commodity_code>    # $-100.00 USD
    || <commodity_code> \h+ <commodity_minus>? <commodity_quantity>                            # USD -100.00
}

token posting {
    <comment> || <account> ** 1 \h+ <transaction> ** 1 [ \h+ <comment> ]?
}

token entry {
    [ ^^ <header> \n ] ** 1
    [ \h ** 2..* <posting> \n ]+
}

token journal {
    ^^ \h* $$ \n                   # blank lines
    || [ ^^ \h* <comment> \n ]+    # comment lines
    || <entry>+                    # journal entries
}

token TOP {
    <journal>*
}

# vim: ft=perl6
