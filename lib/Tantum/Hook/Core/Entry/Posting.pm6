use v6;
use Tantum::Dx::Entry::Posting;
use Tantum::Hook;
use Tantum::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
unit class Hook::Core::Entry::Posting;
also does Hook[POSTING];

has Str:D $!name = 'Entry::Posting';
has Str:D $!description = 'core hook for POSTING';
has Int:D $!priority = 0;
has Hook:U @!dependency;

method dependency(::?CLASS:D: --> Array[Hook:U])
{
    my Hook:U @dependency = @!dependency;
}

method description(::?CLASS:D: --> Str:D)
{
    my Str:D $description = $!description;
}

method name(::?CLASS:D: --> Str:D)
{
    my Str:D $name = $!name;
}

method priority(::?CLASS:D: --> Int:D)
{
    my Int:D $priority = $!priority;
}

multi method apply(
    |c (
        Entry::Posting:D $posting,
        Entry::Header:D $header,
        | (
            Bool:D :$is-entity-open! where .so,
            Bool:D :$is-account-open! where .so,
            |
        )
    )
)
{
    my Entry::Postingʹ:D $postingʹ = apply(|c);
}

multi sub apply(
    Entry::Posting:D $posting where .account.silo == ASSETS,
    Entry::Header:D $header,
    | (
        Bool:D :$contains-aux-asset! where .so,
        Bool:D :$is-xe-present! where .so,
        |
    )
    --> Entry::Postingʹ:D
)
{
    my Bool:D $is-entity-base-currency = False;
    my AssetConvertibilityType:D $convertibility =
        $*config.gen-asset-convertibility($posting);
    my AssetPhysicalityType:D $physicality =
        $*config.gen-asset-physicality($posting);
    my AssetUsageType:D $usage = $*config.gen-asset-usage($posting);
    my AssetType:D $type = $*config.gen-asset-type($posting);
    my Entry::Postingʹ[ASSETS] $postingʹ .=
        new(
            :$posting,
            :$is-entity-base-currency,
            :$convertibility,
            :$physicality,
            :$usage,
            :$type
        );
}

multi sub apply(
    Entry::Posting:D $posting where .account.silo == ASSETS,
    Entry::Header:D $header,
    | (
        Bool:D :$contains-aux-asset! where .not,
        |
    )
    --> Entry::Postingʹ:D
)
{
    my Bool:D $is-entity-base-currency = True;
    my AssetConvertibilityType:D $convertibility =
        $*config.gen-asset-convertibility($posting);
    my AssetPhysicalityType:D $physicality =
        $*config.gen-asset-physicality($posting);
    my AssetUsageType:D $usage = $*config.gen-asset-usage($posting);
    my AssetType:D $type = $*config.gen-asset-type($posting);
    my Entry::Postingʹ[ASSETS] $postingʹ .=
        new(
            :$posting,
            :$is-entity-base-currency,
            :$convertibility,
            :$physicality,
            :$usage,
            :$type
        );
}

multi sub apply(
    Entry::Posting:D $posting where .account.silo == EXPENSES,
    Entry::Header:D $header
    --> Entry::Postingʹ:D
)
{
    my ExpenseDeductibility:D $expense-deductibility =
        $*config.gen-expense-deductibility($posting);
    my Bool:D $is-non-deductible = $expense-deductibility == NON-DEDUCTIBLE;
    my Entry::Postingʹ[EXPENSES] $postingʹ .=
        new(:$posting, :$is-non-deductible);
}

multi sub apply(
    Entry::Posting:D $posting where .account.silo == INCOME,
    Entry::Header:D $header
    --> Entry::Postingʹ:D
)
{
    my IncomeType:D $type = $*config.gen-income-type($posting);
    my Entry::Postingʹ[INCOME] $postingʹ .= new(:$posting, :$type);
}

multi sub apply(
    Entry::Posting:D $posting where .account.silo == LIABILITIES,
    Entry::Header:D $header
    --> Entry::Postingʹ:D
)
{
    my Entry::Postingʹ[LIABILITIES] $postingʹ .= new(:$posting);
}

multi sub apply(
    Entry::Posting:D $posting where .account.silo == EQUITY,
    Entry::Header:D $header
    --> Entry::Postingʹ:D
)
{
    my Entry::Postingʹ[EQUITY] $postingʹ .= new(:$posting);
}

multi method is-match(
    | (
        Bool:D :$is-entity-open! where .so,
        Bool:D :$is-account-open! where .so,
        Bool:D :$contains-aux-asset! where .so,
        Bool:D :$is-xe-present! where .so,
        |
    )
    --> Bool:D
)
{
    # match once we're sure posting looks valid
    my Bool:D $is-match = True;
}

multi method is-match(
    | (
        Bool:D :$is-entity-open! where .so,
        Bool:D :$is-account-open! where .so,
        Bool:D :$contains-aux-asset! where .not,
        |
    )
    --> Bool:D
)
{
    # match once we're sure posting looks valid
    my Bool:D $is-match = True;
}

multi method is-match(
    |
    --> Bool:D
)
{
    # don't match by default
    my Bool:D $is-match = False;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
