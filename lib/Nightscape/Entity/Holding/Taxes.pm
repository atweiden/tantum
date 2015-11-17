use v6;
use Nightscape::Types;
unit class Nightscape::Entity::Holding::Taxes;

# causal EntryID
has EntryID $.entry_id is required;

# acquisition date of funds expended
has DateTime $.acquisition_date is required;

# acquisition price of funds expended
has Price $.acquisition_price is required;

# asset code of acquisition price
has AssetCode $.acquisition_price_asset_code is required;

# average cost of holding being depleted at date of expenditure
has Price $.avco_at_expenditure is required;

# date of expenditure
has DateTime $.date_of_expenditure is required;

# capital gains
has Quantity $.capital_gains = FatRat(0.0);

# capital losses
has Quantity $.capital_losses = FatRat(0.0);

# holding period (long or short term)
has HoldingPeriod $.holding_period = self.get_holding_period.keys[0];

# quantity expended of holding in the making of this Taxes instance
has Quantity $.quantity_expended is required;

# asset code of quantity expended
has AssetCode $.quantity_expended_asset_code is required;

# return days held of asset expended indexed by holding period (short / long)
method get_holding_period() returns Hash[Int:D,HoldingPeriod:D]
{
    # holding period (in days)
    my Int:D $holding_period_in_days =
        $.date_of_expenditure.Date - $.acquisition_date.Date;

    # holding period (long or short term)
    my HoldingPeriod:D $holding_period =
        $holding_period_in_days > 365 ?? LONG_TERM !! SHORT_TERM;

    my Int:D %holding_period{HoldingPeriod:D} =
        $holding_period => $holding_period_in_days;
}

# vim: ft=perl6
