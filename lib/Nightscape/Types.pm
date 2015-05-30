use v6;
unit class Nightscape::Types;

subset Price of Rat is export where * >= 0;

subset Quantity of Rat is export where * >= 0;

subset VarName of Str is export where
{
    use Nightscape::Parser::Grammar;
    Nightscape::Parser::Grammar.parse($_, :rule<var_name>);
};

subset CommodityCode of Str is export where
{
    use Nightscape::Parser::Grammar;
    Nightscape::Parser::Grammar.parse($_, :rule<commodity_code>);
};

enum Silo is export
<
    ASSETS
    EXPENSES
    INCOME
    LIABILITIES
    EQUITY
>;

enum DecInc is export
<
    DEC
    INC
>;

method mksilo(Str $str) returns Silo
{
    my Silo %silo =
        "ASSETS" => ASSETS,
        "EXPENSES" => EXPENSES,
        "INCOME" => INCOME,
        "LIABILITIES" => LIABILITIES,
        "EQUITY" => EQUITY;

    return %silo{$str};
}

method mkdecinc(Bool $commodity_minus) returns DecInc
{
    if $commodity_minus
    {
        return DEC;
    }
    else
    {
        return INC;
    }
}

# vim: ft=perl6
