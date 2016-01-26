use v6;
use Nightscape::Types;
unit class Nightscape::Entity::Holding::Taxes;

# causal EntryID
has EntryID $.entry-id is required;

# acquisition date of funds expended
has DateTime $.acquisition-date is required;

# acquisition price of funds expended
has Price $.acquisition-price is required;

# asset code of acquisition price
has AssetCode $.acquisition-price-asset-code is required;

# average cost of holding being depleted at date of expenditure
has Price $.avco-at-expenditure is required;

# date of expenditure
has DateTime $.date-of-expenditure is required;

# capital gains
has Quantity $.capital-gains = FatRat(0.0);

# capital losses
has Quantity $.capital-losses = FatRat(0.0);

# holding period (long or short term)
has HoldingPeriod $.holding-period = self.get-holding-period.keys[0];

# quantity expended of holding in the making of this Taxes instance
has Quantity $.quantity-expended is required;

# asset code of quantity expended
has AssetCode $.quantity-expended-asset-code is required;

# return days held of asset expended indexed by holding period (short / long)
method get-holding-period() returns Hash[Int:D,HoldingPeriod:D]
{
    # holding period (in days)
    my Int:D $holding-period-in-days =
        $.date-of-expenditure.Date - $.acquisition-date.Date;

    # holding period (long or short term)
    my HoldingPeriod:D $holding-period =
        $holding-period-in-days > 365 ?? LONG-TERM !! SHORT-TERM;

    my Int:D %holding-period{HoldingPeriod:D} =
        $holding-period => $holding-period-in-days;
}

# vim: ft=perl6
