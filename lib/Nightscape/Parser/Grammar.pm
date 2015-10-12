use v6;
unit grammar Nightscape::Parser::Grammar;

token ws
{
    # When parsing file formats where some whitespace (for example
    # vertical whitespace) is significant, it is advisable to
    # override ws:
    <!ww>    # only match when not within a word
    \h*      # only match horizontal whitespace
}

token blank_line
{
    ^^ \h* $$ \n
}

token comment
{
    '#' \N*
}

token year
{
    \d ** 4
}

token month
{
    0 <[1..9]> || 1 <[0..2]>
}

token day
{
    <[0..2]> \d || 3 <[0..1]>
}

token iso_date
{
    <year> '-' <month> '-' <day>
}

token var_char
{
    <:Letter>
    || <:Number>
    || <[_-]>
}

token acct_name
{
    [<var_char> || ':']+
}

token var_name
{
    <var_char>+
}

token tag
{
    '@' <var_name>
}

token exclamation_mark
{
    '!'
}

token important
{
    <exclamation_mark>+
}

token description
{
    # double quoted string
    '"'
    <-["\\]>*
    [ \\ . <-["\\]>* ]*
    '"'

    ||

    # single quoted string
    '\''
    <-[\'\\]>*
    [ \\ . <-[\'\\]>* ]*
    '\''
}

token header
{
    <iso_date>
    [ \h+ <description> ]?
    [ \h+ [ <tag> || <important> ] ]*
    \h* <eol_comment=.comment>?
}

token silo
{
    [ :i
       Asset[s]?
    || Expense[s]?
    || Income || Revenue[s]?
    || Liabilit[y|ies]
    || Equit[y|ies]
    ]
}

token reserved
{
    [ :i
       assets
       || 'base-costing'
       || 'base-currency'
    ]
}

token account_sub
{
    <var_char>+
}

token account
{
    <silo> ':' <entity=.account_sub> [ ':' <account_sub> ]*
}

token minus_sign
{
    '-'
}

token asset_symbol
{
    \D+
}

token asset_code
{
    <:Letter>+
}

token asset_quantity
{
    \d+ [ '.' \d+ ]?
    || '.' \d+
}

token exchange_rate
{
    '@' \h+
    [
        <asset_symbol>? \h* <asset_quantity> \h+ <asset_code>    # @ $830.024 USD
        || <asset_code> \h+ <asset_quantity>                     # @ USD 830.024
    ]
}

token amount
{
    <minus_sign>? <asset_symbol>? \h* <asset_quantity>
        \h+ <asset_code> [\h+ <exchange_rate>]?              # -$100.00 USD
    || <asset_symbol>? \h* <minus_sign>? <asset_quantity>
            \h+ <asset_code> [\h+ <exchange_rate>]?          # $-100.00 USD
    || <asset_code> \h+ <minus_sign>? <asset_quantity>
        [\h+ <exchange_rate>]?                               # USD -100.00
}

token posting
{
    <account> \h+ <amount> [\h+ <eol_comment=.comment>]?
}

token entry
{
    ^^ <header> $$ \n
    [
        ^^ \h ** 2..*
        [
            <posting> || <posting_comment=.comment>
        ]
        $$ \n
    ]+
}

token include
{
    ^^ include \h+ <filename=.description> \h* $$ \n
}

token journal
{
    <blank_line>                               # blank lines
    || ^^ \h* <comment_line=.comment> $$ \n    # comment lines
    || <entry>                                 # journal entries
    || <include>                               # includes
}

token TOP
{
    <journal>*
}

# vim: ft=perl6
