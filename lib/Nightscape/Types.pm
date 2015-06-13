use v6;
unit class Nightscape::Types;

subset AssetCode of Str is export where
{
    use Nightscape::Parser::Grammar;
    Nightscape::Parser::Grammar.parse($_, :rule<asset_code>);
};

subset Price of Rat is export where * >= 0;

subset Quantity of Rat is export where * >= 0;

subset VarName of Str is export where
{
    use Nightscape::Parser::Grammar;
    Nightscape::Parser::Grammar.parse($_, :rule<var_name>);
};

enum AssetFlow is export
<
    ACQUIRE
    EXPEND
    STABLE
>;

enum Costing is export
<
    AVCO
    FIFO
    LIFO
>;

enum DecInc is export
<
    DEC
    INC
>;

enum Silo is export
<
    ASSETS
    EXPENSES
    INCOME
    LIABILITIES
    EQUITY
>;

enum Taxable is export
<
    GAIN
    LOSS
>;

method mkasset_flow(Rat $d) returns AssetFlow
{
    if $d > 0
    {
        ACQUIRE
    }
    elsif $d < 0
    {
        EXPEND
    }
    else
    {
        STABLE
    }
}

method mkdecinc(Bool $minus_sign) returns DecInc
{
    if $minus_sign
    {
        DEC;
    }
    else
    {
        INC;
    }
}

# vim: ft=perl6
