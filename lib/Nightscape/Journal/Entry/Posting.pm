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

# vim: ft=perl6
