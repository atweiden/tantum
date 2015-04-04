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
    ';' \N*
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
    <year> '-' <month> '-' <day>
}

token hashtag {
    '#' \w+
}

token var_char {
    <:Letter>
    || <:Number>
    || <[_-]>
}

token var_name {
    <var_char>+
}

token group_pos {
    \d+
}

token group {
    '@' <group_name=.var_name> '[' <group_pos> ']'
}

token description {
    '"'
    <-["\\]>*
    [ \\ . <-["\\]>* ]*
    '"'
}

token header {
    <iso_date>
    [ \h+ <description> ]?
    [ \h+ [ <hashtag> || <group> ] ]*
    \h* <comment>?
}

token account_main {
    [ :i
       Asset[s]?
    || Expense[s]?
    || Income || Revenue[s]?
    || Liabilit[y|ies]
    || Equit[y|ies]
    ]
}

token account_sub {
    <var_char>+
}

token account {
    <account_main>
    ':' <entity=.account_sub>
    [ ':' <account_sub> ]*
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

token exchange_rate {
    '@' \h+
    [
        <commodity_symbol>? \h* <commodity_quantity> \h+ <commodity_code>    # @ $830.024 USD
        || <commodity_code> \h+ <commodity_quantity>                         # @ USD 830.024
    ]
}

token transaction {
    <commodity_minus>? <commodity_symbol>? \h* <commodity_quantity> \h+ <commodity_code> [\h+ <exchange_rate>]?       # -$100.00 USD
    || <commodity_symbol>? \h* <commodity_minus>? <commodity_quantity> \h+ <commodity_code> [\h+ <exchange_rate>]?    # $-100.00 USD
    || <commodity_code> \h+ <commodity_minus>? <commodity_quantity> [\h+ <exchange_rate>]?                            # USD -100.00
}

token posting {
    <comment> || <account> ** 1 \h+ <transaction> ** 1 [\h+ <comment>]?
}

token entry {
    [ ^^ <header> $$ \n ] ** 1
    [ ^^ \h ** 2..* <posting> $$ \n ]+
}

token journal {
    ^^ \h* $$ \n                 # blank lines
    || ^^ \h* <comment> $$ \n    # comment lines
    || <entry>                   # journal entries
}

token TOP {
    <journal>*
}

# vim: ft=perl6
