use v6;
use Tantum::Dx::Entry::Posting::Meta;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;

my role Common
{...}

role Entry::Postingʹ[ASSETS]
{
    also does Common;
    also does Entry::Postingʹ::Meta[ASSETS];
}

role Entry::Postingʹ[EXPENSES]
{
    also does Common;
    also does Entry::Postingʹ::Meta[EXPENSES];
}

role Entry::Postingʹ[INCOME]
{
    also does Common;
    also does Entry::Postingʹ::Meta[INCOME];
}

role Entry::Postingʹ[LIABILITIES]
{
    also does Common;
    also does Entry::Postingʹ::Meta[LIABILITIES];
}

role Entry::Postingʹ[EQUITY]
{
    also does Common;
    also does Entry::Postingʹ::Meta[EQUITY];
}

my role Common
{
    # C<Entry::Posting> from which C<Entry::Postingʹ> is derived
    has Entry::Posting:D $.posting is required;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
