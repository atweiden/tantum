use v6;
use Nightscape::Entity::Holding::Basis::Depletion;
use Nightscape::Types;
unit class Nightscape::Entity::Holding::Basis;

# causal EntryID
has EntryID $.entry-id is required;

# date, price, quantity
has DateTime $.date is required;
has Price $.price is required;

# TODO: rework quantity in style of Changeset
has Quantity $.quantity is required;

# for each expenditure, causal EntryID and associated quantity expended
has Nightscape::Entity::Holding::Basis::Depletion %.depletions{EntryID};

# decrease units held in this basis lot
method deplete(
    GreaterThanZero:D :$quantity!,
    EntryID:D :$entry-id!,
    DateTime:D :$acquisition-date!,
    Price:D :$acquisition-price!,
    AssetCode:D :$acquisition-price-asset-code!,
    Price:D :$avco-at-expenditure!,
    DateTime:D :$date-of-expenditure!
)
{
    # check for sufficient unit quantity of asset in holdings
    unless $quantity <= $.quantity
    {
        die "Sorry, cannot deplete from basis: insufficient quantity.";
    }

    # check to make sure this EntryID hasn't previously expended this basis
    # lot, deplete should only be possible once per entry
    if %.depletions{$entry-id}
    {
        die "Sorry, same EntryID previously depleted this basis lot.";
    }

    # decrease quantity
    $!quantity -= $quantity;

    # record causal EntryID of depletion with quantity depleted
    %!depletions{$entry-id} = Nightscape::Entity::Holding::Basis::Depletion.new(
        :$entry-id,
        :$acquisition-date,
        :$acquisition-price,
        :$acquisition-price-asset-code,
        :$avco-at-expenditure,
        :$date-of-expenditure,
        :$quantity
    );
}

# vim: ft=perl6
