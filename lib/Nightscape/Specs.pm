use v6;
class Nightscape::Specs;

subset Price of Rat is export where * > 0;

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

enum DrCr is export
<
    DEBIT
    CREDIT
>;

method mksilo(Str $str) returns Silo
{
    my Silo %silo = "ASSETS" => ASSETS,
                    "EXPENSES" => EXPENSES,
                    "INCOME" => INCOME,
                    "LIABILITIES" => LIABILITIES,
                    "EQUITY" => EQUITY;
    return %silo{$str};
}

method mkdrcr(Bool $commodity_minus) returns DrCr
{
    if $commodity_minus
    {
        return DEBIT;
    }
    else
    {
        return CREDIT;
    }
}

# vim: ft=perl6
