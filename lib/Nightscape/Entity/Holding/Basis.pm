use v6;
use Nightscape::Entity::Holding::Basis::Depletion;
use Nightscape::Types;
unit class Nightscape::Entity::Holding::Basis;

# causal EntryID
has EntryID $.entry_id;

# date, price, quantity
has DateTime $.date;
has Price $.price;

# TODO: rework quantity in style of Changeset
has Quantity $.quantity;

# for each expenditure, causal EntryID and associated quantity expended
has Nightscape::Entity::Holding::Basis::Depletion %.depletions{EntryID};

# decrease units held in this basis lot
method deplete(
    GreaterThanZero:D :$quantity!,
    EntryID:D :$entry_id!,
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

    # check to make sure this EntryID hasn't previously expended this basis
    # lot, deplete should only be possible once per entry
    if %.depletions{$entry_id}
    {
        die "Sorry, same EntryID previously depleted this basis lot.";
    }

    # decrease quantity
    $!quantity -= $quantity;

    # record causal EntryID of depletion with quantity depleted
    %!depletions{$entry_id} = Nightscape::Entity::Holding::Basis::Depletion.new(
        :$entry_id,
        :$acquisition_date,
        :$acquisition_price,
        :$acquisition_price_asset_code,
        :$avco_at_expenditure,
        :$date_of_expenditure,
        :$quantity
    );
}

# vim: ft=perl6
