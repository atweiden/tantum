use v6;
use Nightscape::Entry::Posting::Amount::XE;
use Nightscape::Types;
unit class Nightscape::Entry::Posting::Amount;

has AssetCode $.asset_code;
has Quantity $.asset_quantity;
has Str $.asset_symbol;
has Str $.minus_sign;
has Nightscape::Entry::Posting::Amount::XE $.exchange_rate;

# update exchange rate in-place
method mkxe(
    AssetCode:D :$posting_entity_base_currency!,
    Quantity:D :$price!,
    Bool :$force
)
{
    # instantiate XE and store in $.exchange_rate
    sub init()
    {
        $!exchange_rate = Nightscape::Entry::Posting::Amount::XE.new(
            :asset_code($posting_entity_base_currency),
            :asset_quantity($price)
        );
    }

    # was :force arg passed to the method?
    if $force
    {
        # instantiate XE and store in $.exchange_rate overwriting XE if it exists
        init();
    }
    # does XE exist?
    elsif $.exchange_rate
    {
        # error: can't overwrite exchange rate
        die "Sorry, can't update existing exchange rate in-place";
    }
    else
    {
        # no exchange rate exists, instantiate XE and store in $.exchange_rate
        init();
    }
}

# vim: ft=perl6
