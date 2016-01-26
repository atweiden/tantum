use v6;
use Nightscape::Entity::Holding::Basis;
use Nightscape::Entity::Holding::Taxes;
use Nightscape::Types;
unit class Nightscape::Entity::Holding;

# asset code
has AssetCode $.asset-code is required;

# average cost of units held
has Price $.avco;

# cost basis of units held (date, price, quantity)
has Nightscape::Entity::Holding::Basis @.basis;

# tax consequences indexed by causal EntryID
has Array[Nightscape::Entity::Holding::Taxes] %.taxes{EntryID};

# increase entity's holdings
method acquire(
    EntryID:D :$entry-id!,
    DateTime:D :$date!,
    Price:D :$price!,
    Quantity:D :$quantity! where * > 0
)
{
    # add to holdings
    push @!basis, Nightscape::Entity::Holding::Basis.new(
        :$entry-id,
        :$date,
        :$price,
        :$quantity
    );

    # update average cost
    $!avco = self.gen-avco;
}

# decrease entity's holdings via AVCO/FIFO/LIFO inventory costing method
method expend(
    AssetCode:D :$asset-code!,
    EntryID:D :$entry-id!,
    DateTime:D :$date!,
    Costing:D :$costing!,
    Price:D :$price!,
    AssetCode:D :$acquisition-price-asset-code!,
    Quantity:D :$quantity! where * > 0
)
{
    # check for sufficient unit quantity of asset in holdings
    unless self.in-stock($quantity)
    {
        say qq:to/EOF/;
        Sorry, cannot expend: found insufficient quantity of asset
        in holdings.
        EOF
        die X::Nightscape::Entity::Holding::Expend::OutOfStock.new(:$entry-id);
    }

    # find array indices of Basis with sufficient units to expend,
    # starting from the beginning of the list for AVCO/FIFO, end of
    # the list for LIFO, along with the number of units to expend per
    # array index
    my Quantity @targets = self.find-targets(:$costing, :$quantity);

    # deplete units in targeted basis lots
    # has side effect of recording capital gains/losses to %.taxes
    sub rmtargets(FatRat :@targets! where * >= 0) # When typecheck: Quantity => Constraint type check failed for parameter '@targets'
    {
        # for each @.basis lot target index $i and associated quantity $q
        for @targets.pairs.kv -> $i, $q
        {
            # necessary since array can contain skipped basis lot index targets
            unless $q.value
            {
                next;
            }

            # get value of $q pair
            my Quantity $qty = $q.value;

            # get scalar container of basis lot
            my Nightscape::Entity::Holding::Basis $basis := @!basis[$i];

            # acquisition date
            my DateTime $acquisition-date = $basis.date;

            # date of expenditure
            my DateTime $date-of-expenditure = $date;

            # try decreasing units by quantity
            $basis.deplete(
                :$entry-id,
                :quantity($qty),
                :$acquisition-date,
                :acquisition-price($basis.price),
                :$acquisition-price-asset-code,
                :avco-at-expenditure($.avco),
                :$date-of-expenditure
            );

            # for calculating capital gains/losses
            my FatRat $d;

            # AVCO inventory valuation method?
            if $costing ~~ AVCO
            {
                # (expend price - average cost) * quantity expended
                $d = FatRat(($price - $.avco) * $qty);
            }
            # FIFO or LIFO inventory valuation method?
            elsif $costing ~~ FIFO or $costing ~~ LIFO
            {
                # (expend price - acquisition price) * quantity expended
                $d = FatRat(($price - $basis.price) * $qty);
            }

            if $d > 0
            {
                # record capital gains
                my Quantity $capital-gains = FatRat($d.abs);
                push %!taxes{$entry-id}, Nightscape::Entity::Holding::Taxes.new(
                    :$entry-id,
                    :$acquisition-date,
                    :acquisition-price($basis.price),
                    :$acquisition-price-asset-code,
                    :avco-at-expenditure($.avco),
                    :$date-of-expenditure,
                    :$capital-gains,
                    :quantity-expended($qty),
                    :quantity-expended-asset-code($.asset-code)
                );
            }
            elsif $d < 0
            {
                # record capital losses
                my Quantity $capital-losses = FatRat($d.abs);
                push %!taxes{$entry-id}, Nightscape::Entity::Holding::Taxes.new(
                    :$entry-id,
                    :$acquisition-date,
                    :acquisition-price($basis.price),
                    :$acquisition-price-asset-code,
                    :avco-at-expenditure($.avco),
                    :$date-of-expenditure,
                    :$capital-losses,
                    :quantity-expended($qty),
                    :quantity-expended-asset-code($.asset-code)
                );
            }
            else
            {
                # no gains or losses to report
                push %!taxes{$entry-id}, Nightscape::Entity::Holding::Taxes.new(
                    :$entry-id,
                    :$acquisition-date,
                    :acquisition-price($basis.price),
                    :$acquisition-price-asset-code,
                    :avco-at-expenditure($.avco),
                    :$date-of-expenditure,
                    :quantity-expended($qty),
                    :quantity-expended-asset-code($.asset-code)
                );
            }
        }
    }

    # expend targets
    rmtargets(:@targets);
}

# identify unit quantities to be expended, indexed by @.basis array index
method find-targets(
    Costing:D :$costing!,
    Quantity:D :$quantity! where * > 0
) returns Array[Quantity] # returned Quantity can be undefined in cases where basis array index is skipped
{
    # basis lots, to be reversed when LIFO costing method is used
    my Nightscape::Entity::Holding::Basis @basis;
    $costing ~~ LIFO ?? (@basis = @.basis.reverse) !! (@basis = @.basis);

    # units to expend, indexed by @.basis array index
    my Quantity @targets;

    # @.basis array index count
    my Int $count = 0;

    # running total
    my Quantity $remaining = $quantity;

    # fill in targets as needed
    for @basis -> $basis
    {
        # are more units still needed?
        if $remaining > 0
        {
            # is the quantity of units in this basis lot less than
            # the amount of units still needed?
            if $remaining >= $basis.quantity
            {
                # target all units in this basis lot
                @targets[$count] = $basis.quantity;

                # subtract all units in this basis lot from remaining
                $remaining -= $basis.quantity;

                # increment @.basis array index if remaining targets, else break
                $remaining > 0 ?? $count++ !! last;
            }
            # is the quantity of units in this basis greater than or
            # equal to the amount of units still needed?
            else
            {
                # target only the units necessary from this basis lot
                @targets[$count] = $remaining;

                # no more units are remaining
                $remaining -= $remaining;
                last;
            }
        }
        else
        {
            # no more units needed
            last;
        }
    }

    @targets;
}

# calculate average cost of current holdings
method gen-avco() returns Price:D
{
    # calculate total value of units held
    my Price $value = self.get-total-value;

    # calculate total quantity of units held
    my Quantity $quantity = self.get-total-quantity;

    # weighted average cost
    my Price $avco = FatRat($value / $quantity);
}

# calculate total quantity of units held
method get-total-quantity(
    Nightscape::Entity::Holding::Basis:D :@basis is readonly = @.basis
) returns Quantity:D
{
    my Quantity $quantity = [+] (.quantity for @basis);
    $quantity;
}

# calculate total value of units held
# by default assumes price paid at acquisition
# pass :market for market price (NYI)
method get-total-value(
    Nightscape::Entity::Holding::Basis:D :@basis is readonly = @.basis,
    Bool :$market
) returns Price:D
{
    my Price $value = [+] (.price * .quantity for @basis);
    $value;
}

# check for sufficient unit quantity of asset in holdings
method in-stock(Quantity:D $quantity) returns Bool:D
{
    $quantity <= self.get-total-quantity ?? True !! False;
}

# vim: ft=perl6
