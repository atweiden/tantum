use v6;
use Nightscape::Parser::Grammar;
unit class Nightscape::Types;

subset AcctName of Str is export where
{
    Nightscape::Parser::Grammar.parse($_, :rule<acct_name>);
}

subset AssetsAcctName of AcctName is export where * ~~ / ^ASSETS ':' \N+$ /;

subset AssetCode of Str is export where
{
    Nightscape::Parser::Grammar.parse($_, :rule<asset_code>);
}

subset GreaterThanZero of Rat is export where * > 0;

subset Instruction of Hash is export where
{
    .keys.sort ~~ <acct_name newmod posting_uuid quantity_to_debit xe>;
}

subset LessThanZero of Rat is export where * < 0;

subset Price of Rat is export where * >= 0;

subset Quantity of Rat is export where * >= 0;

subset VarName of Str is export where
{
    Nightscape::Parser::Grammar.parse($_, :rule<var_name>);
}

enum AssetFlow is export <ACQUIRE EXPEND STABLE>;

enum Costing is export <AVCO FIFO LIFO>;

enum DecInc is export <DEC INC>;

enum NewMod is export <NEW MOD>;

enum Silo is export <ASSETS EXPENSES INCOME LIABILITIES EQUITY>;

method mkasset_flow(Rat $d) returns AssetFlow
{
    if $d > 0
    {
        ACQUIRE;
    }
    elsif $d < 0
    {
        EXPEND;
    }
    else
    {
        STABLE;
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
