use v6;
use Nightscape::Entity::Holding::Basis::Depletion;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::Holding::Basis;

# causal entry's UUID
has UUID $.uuid;

# date, price, quantity
has Date $.date;
has Price $.price;
has Quantity $.quantity;

# for each expenditure, causal entry's UUID and associated quantity expended
has Nightscape::Entity::Holding::Basis::Depletion %.depletions{UUID};

# decrease units held in this basis lot
method deplete(
    Quantity :$quantity! where * > 0,
    UUID :$uuid!,
    Price :$acquisition_price!,
    AssetCode :$acquisition_price_asset_code!,
    Price :$avco_at_expenditure!
)
{
    # check for sufficient unit quantity of asset in holdings
    unless $quantity <= $.quantity
    {
        die "Sorry, cannot deplete from basis: insufficient quantity.";
    }

    # check to make sure this UUID hasn't previously expended this basis
    # lot, deplete should only be possible once per entry
    if %.depletions{$uuid}
    {
        die "Sorry, same entry UUID previously depleted this basis lot.";
    }

    # decrease quantity
    $!quantity -= $quantity;

    # record causal entry UUID of depletion with quantity depleted
    %!depletions{$uuid} = Nightscape::Entity::Holding::Basis::Depletion.new(
        :$uuid,
        :$acquisition_price,
        :$acquisition_price_asset_code,
        :$avco_at_expenditure,
        :$quantity
    );
}

# vim: ft=perl6
