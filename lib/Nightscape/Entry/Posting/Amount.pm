use v6;
use Nightscape::Entry::Posting::Amount::XE;
use Nightscape::Types;
unit class Nightscape::Entry::Posting::Amount;

has AssetCode $.asset-code is required;
has Quantity $.asset-quantity is required;
has Str $.asset-symbol;
has Str $.plus-or-minus;
has Nightscape::Entry::Posting::Amount::XE $.exchange-rate;

# update exchange rate in-place
method mkxe(
    AssetCode:D :$posting-entity-base-currency!,
    Quantity:D :$price!,
    Bool :$force
)
{
    # instantiate XE and store in $.exchange-rate
    sub init()
    {
        $!exchange-rate = Nightscape::Entry::Posting::Amount::XE.new(
            :asset-code($posting-entity-base-currency),
            :asset-quantity($price)
        );
    }

    # was :force arg passed to the method?
    if $force
    {
        # instantiate XE and store in $.exchange-rate overwriting XE if it exists
        init();
    }
    # does XE exist?
    elsif $.exchange-rate
    {
        # error: can't overwrite exchange rate
        die "Sorry, can't update existing exchange rate in-place";
    }
    else
    {
        # no exchange rate exists, instantiate XE and store in $.exchange-rate
        init();
    }
}

# vim: ft=perl6
