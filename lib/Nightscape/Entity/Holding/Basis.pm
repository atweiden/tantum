use v6;
use Nightscape::Entity::Holding::Basis::Depletion;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::Holding::Basis;

# causal entry's UUID
has UUID $.uuid;

# date, price, quantity
has DateTime $.date;
has Price $.price;

# TODO: rework quantity in style of Changeset
has Quantity $.quantity;

# for each expenditure, causal entry's UUID and associated quantity expended
has Nightscape::Entity::Holding::Basis::Depletion %.depletions{UUID};

# decrease units held in this basis lot
method deplete(
    GreaterThanZero:D :$quantity!,
    UUID:D :$uuid!,
    DateTime:D :$acquisition_date!,
    Price:D :$acquisition_price!,
    AssetCode:D :$acquisition_price_asset_code!,
    Price:D :$avco_at_expenditure!,
    DateTime:D :$date_of_expenditure!
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
        :$acquisition_date,
        :$acquisition_price,
        :$acquisition_price_asset_code,
        :$avco_at_expenditure,
        :$date_of_expenditure,
        :$quantity
    );
}

# vim: ft=perl6
