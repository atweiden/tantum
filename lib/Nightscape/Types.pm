use v6;
unit class Nightscape::Types;

subset Price of Rat is export where * >= 0;

subset Quantity of Rat is export where * >= 0;

subset VarName of Str is export where
{
    use Nightscape::Parser::Grammar;
    Nightscape::Parser::Grammar.parse($_, :rule<var_name>);
};

subset AssetCode of Str is export where
{
    use Nightscape::Parser::Grammar;
    Nightscape::Parser::Grammar.parse($_, :rule<asset_code>);
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

method mkdecinc(Bool $minus_sign) returns DecInc
{
    if $minus_sign
    {
        return DEC;
    }
    else
    {
        return INC;
    }
}

# vim: ft=perl6
