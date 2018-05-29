use v6;
use Nightscape::Types;
use TXN::Parser::Types;

role Entry::Postingʹ::Meta[ASSETS]
{
    # posting denominated in entity's base currency?
    has Bool:D $.is-entity-base-currency is required;
    # classification of asset
    has AssetConvertibilityType:D $.convertibility is required;
    has AssetPhysicalityType:D $.physicality is required;
    has AssetUsageType:D $.usage is required;
    # balance sheet line item
    has AssetType:D $.type is required;
}

role Entry::Postingʹ::Meta[EXPENSES]
{
    # non-deductible expense?
    has Bool:D $.is-non-deductible is required;
}

role Entry::Postingʹ::Meta[INCOME]
{
    has IncomeType:D $.type is required;
}

role Entry::Postingʹ::Meta[LIABILITIES]
{*}

role Entry::Postingʹ::Meta[EQUITY]
{*}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
