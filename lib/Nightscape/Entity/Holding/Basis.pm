use v6;
use Nightscape::Types;
unit class Nightscape::Entity::Holding::Basis;

has Date $.date;
has Price $.price;
has Quantity $.quantity;

# decrease units held in this basis lot
method deplete(Quantity $q where * > 0)
{
    # check for sufficient unit quantity of asset in holdings
    unless $q <= $!quantity
    {
        die "Sorry, cannot deplete from basis: insufficient quantity.";
    }

    # decrease quantity
    $!quantity -= $q;
}

# vim: ft=perl6
