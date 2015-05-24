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
    '"'
    <-["\\]>*
    [ \\ . <-["\\]>* ]*
    '"'
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
       currencies
    || 'base-currency'
    ]
}

token account_sub
{
    <var_char>+
}

token account
{
    <silo>
    ':' <entity=.account_sub>
    {
        $/ !~~ / [ :i currencies || 'base-currency' ] /
            or die "Sorry, use of reserved word ($/) as an entity or",
                " account name is forbidden";
    }
    [
        ':' <account_sub>
        {
            $/ !~~ / [ :i currencies || 'base-currency' ] /
                or die "Sorry, use of reserved word ($/) as an entity or",
                    " account name is forbidden";
        }
    ]*
}

token commodity_minus
{
    '-'
}

token commodity_symbol
{
    \D+
}

token commodity_code
{
    <:Letter>+
}

token commodity_quantity
{
    \d+ [ '.' \d+ ]?
    || '.' \d+
}

token exchange_rate
{
    '@' \h+
    [
        <commodity_symbol>? \h* <commodity_quantity> \h+ <commodity_code>    # @ $830.024 USD
        || <commodity_code> \h+ <commodity_quantity>                         # @ USD 830.024
    ]
}

token amount
{
    <commodity_minus>? <commodity_symbol>? \h* <commodity_quantity>
        \h+ <commodity_code> [\h+ <exchange_rate>]?                       # -$100.00 USD
    || <commodity_symbol>? \h* <commodity_minus>? <commodity_quantity>
            \h+ <commodity_code> [\h+ <exchange_rate>]?                   # $-100.00 USD
    || <commodity_code> \h+ <commodity_minus>? <commodity_quantity>
        [\h+ <exchange_rate>]?                                            # USD -100.00
}

token posting
{
    <account> ** 1 \h+ <amount> ** 1 [\h+ <eol_comment=.comment>]?
}

token entry
{
    [ ^^ <header> $$ \n ] ** 1
    [
        ^^ \h ** 2..*
        [
            <posting> || <posting_comment=.comment>
        ]
        $$ \n
    ]+
}

token journal
{
    <blank_line>                               # blank lines
    || ^^ \h* <comment_line=.comment> $$ \n    # comment lines
    || <entry>                                 # journal entries
}

token TOP
{
    <journal>*
}

# vim: ft=perl6
