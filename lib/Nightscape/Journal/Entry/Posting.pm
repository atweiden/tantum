use v6;
class Nightscape::Journal::Entry::Posting;

enum Silo is export <
    ASSETS
    EXPENSES
    INCOME
    LIABILITIES
    EQUITY
>;
enum DrCr is export <
    DEBIT
    CREDIT
>;

has $.silo;
has $.drcr;
has $.entity;
has @.subaccount;
has %.amounts;

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
