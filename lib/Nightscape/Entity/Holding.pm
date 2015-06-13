use v6;
use Nightscape::Entity::Holding::Basis;
use Nightscape::Types;
unit class Nightscape::Entity::Holding;

# asset code
has AssetCode $.asset_code;

# average cost of units held
has Price $.avco;

# cost basis of units held (date, price, quantity)
has Nightscape::Entity::Holding::Basis @.basis;

# for storing capital gains / capital losses incurred via expenditures
has Hash[Price,Taxable] %.tax{Int};

# increase entity's holdings
method acquire(
    Date :$date!,
    Price :$price!,
    Quantity :$quantity! where * > 0
)
{
    # add to holdings
    push @!basis, Nightscape::Entity::Holding::Basis.new(
        :$date,
        :$price,
        :$quantity
    );

    # update average cost
    $!avco = self.gen_avco;
}

# decrease entity's holdings via AVCO/FIFO/LIFO inventory costing method
method expend(
    Costing :$costing!,
    Price :$price!,
    Quantity :$quantity! where * > 0
)
{
    # check for sufficient unit quantity of asset in holdings
    unless self.in_stock($quantity)
    {
        die qq:to/EOF/;
        Sorry, cannot expend: found insufficient quantity of asset
        in holdings.
        EOF
    }

    # find array indices of Basis with sufficient units to expend,
    # starting from the beginning of the list for AVCO/FIFO, end of
    # the list for LIFO, along with the number of units to expend per
    # array index
    my Quantity %targets{Int} = self.find_targets(:$costing, :$quantity);

    # deplete units in targeted basis lots
    # has side effect of recording capital gains/losses to %!tax
    sub rmtargets(Quantity :%targets!)
    {
        # for each @!basis lot target index $i and associated quantity $q
        for %targets.kv -> $i, $q
        {
            # get scalar container of basis lot
            my Nightscape::Entity::Holding::Basis $basis := @!basis[$i];

            # for calculating capital gains/losses
            my Rat $d;

            # AVCO inventory valuation method?
            if $costing ~~ AVCO
            {
                # expend price - average cost
                $d = $price - $!avco;
            }
            # FIFO or LIFO inventory valuation method?
            elsif $costing ~~ FIFO or $costing ~~ LIFO
            {
                # expend price - acquisition price
                $d = $price - $basis.price;
            }

            if $d > 0
            {
                # record capital gains
                %!tax{$i} = ::(GAIN) => $d.abs
            }
            elsif $d < 0
            {
                # record capital losses
                %!tax{$i} = ::(LOSS) => $d.abs
            }
            else
            {
                # no gains or losses to report
            }

            # decrease units by quantity
            $basis.deplete($q);
        }
    }

    # expend targets
    &rmtargets(:%targets);
}

# identify unit quantities to be expended, indexed by @!basis array index
method find_targets(
    Costing :$costing!,
    Quantity :$quantity! where * > 0
) returns Hash[Quantity,Int]
{
    # units to expend, indexed by @!basis array index
    my Quantity %targets{Int};

    # @!basis array index count
    my Int $count = 0;

    # running total
    my Quantity $remaining = $quantity;

    # fill in targets as needed
    sub mktarget(Nightscape::Entity::Holding::Basis $basis)
    {
        # are more units still needed?
        if $remaining > 0
        {
            # is the quantity of units in this basis lot less than
            # the amount of units still needed?
            if $basis.quantity <= $remaining
            {
                # target all units in this basis lot
                %targets{$count} = $basis.quantity;

                # subtract all units in this basis lot from remaining
                $remaining -= $basis.quantity;

                # increment @!basis array index
                $count++;
            }
            else
            {   # target only the units necessary from this basis lot
                %targets{$count} = $remaining;

                # no more units are remaining
                $remaining -= $remaining;
            }
        }
    }

    # is inventory valuation method AVCO or FIFO?
    if $costing ~~ AVCO or $costing ~~ FIFO
    {
        # find units starting from beginning of @!basis
        &mktarget($_) for @!basis;
    }
    # is inventory valuation method LIFO?
    elsif $costing ~~ LIFO
    {
        # find units starting from end of @!basis
        &mktarget($_) for @!basis.reverse;
    }

    %targets;
}

# calculate average cost of current holdings
method gen_avco() returns Price
{
    # calculate total value of units held
    my Price $value = self.get_total_value;

    # calculate total quantity of units held
    my Quantity $quantity = self.get_total_quantity;

    # weighted average cost
    $value / $quantity;
}

# calculate total quantity of units held
method get_total_quantity(
    Nightscape::Entity::Holding::Basis :@basis = @!basis
) returns Quantity
{
    my Quantity @quantity = [+] .quantity for @basis;
}

# calculate total value of units held
# by default assumes price paid at acquisition
# pass :market for market price (NYI)
method get_total_value(
    Nightscape::Entity::Holding::Basis :@basis = @!basis,
    Bool :$market
) returns Price
{
    my Price @value;
    for @basis -> $b
    {
        my Price $p = $b.price;
        my Quantity $q = $b.quantity;
        my Price $v = $p * $q;
        push @value, $v;
    }
    my Price $value = [+] @value;
}

# check for sufficient unit quantity of asset in holdings
method in_stock(Quantity $quantity) returns Bool
{
    $quantity <= self.get_total_quantity ?? True !! False;
}

# vim: ft=perl6
