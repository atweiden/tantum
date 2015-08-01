use v6;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::Holding::Taxes;

# causal entry's UUID
has UUID $.uuid;

# acquisition date of funds expended
has Date $.acquisition_date;

# acquisition price of funds expended
has Price $.acquisition_price;

# asset code of acquisition price
has AssetCode $.acquisition_price_asset_code;

# average cost of holding being depleted at date of expenditure
has Price $.avco_at_expenditure;

# date of expenditure
has Date $.date_of_expenditure;

# capital gains
has Quantity $.capital_gains = 0.0;

# capital losses
has Quantity $.capital_losses = 0.0;

# holding period (long or short term)
has HoldingPeriod $.holding_period = self.get_holding_period.keys[0];

# quantity expended of holding in the making of this Taxes instance
has Quantity $.quantity_expended;

# asset code of quantity expended
has AssetCode $.quantity_expended_asset_code;

# return days held of asset expended indexed by holding period (short / long)
method get_holding_period() returns Hash[Int:D,HoldingPeriod:D]
{
    # holding period (in days)
    my Int $holding_period_in_days = $.date_of_expenditure - $.acquisition_date;

    # holding period (long or short term)
    my HoldingPeriod $holding_period =
        $holding_period_in_days > 365 ?? LONG_TERM !! SHORT_TERM;

    my Int %holding_period{HoldingPeriod} =
        $holding_period => $holding_period_in_days;
}

# vim: ft=perl6
