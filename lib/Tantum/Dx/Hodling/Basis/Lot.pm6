use v6;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;

# p6doc {{{

=begin pod
=head NAME

C<Hodling::Basis::Lot>

=head SYNOPSIS

    use Tantum::Dx::Hodling::Basis::Lot;
    use TXN::Parser::Types;
    use TXN::Parser::ParseTree;
    my AssetCode:D $asset-code = 'CAD';
    my Entry::ID $entry-id .= new(:number[0], :xxhash(12345), :text<text>);
    my Date $date .= new(now);
    my Price:D $price = 0.75;
    my Quantity:D $quantity = 7.0;
    my VarName:D $name = 'mtl-summer';
    # instantiate named lot
    my Hodling::Basis::Lot::Named[$asset-code] =
        Hodling::Basis::Lot.new(
            :$asset-code,
            :$entry-id,
            :$date,
            :$price,
            :$quantity,
            :$name
        );
    # instantiate unnamed lot
    my Hodling::Basis::Lot::Unnamed[$asset-code] =
        Hodling::Basis::Lot.new(
            :$asset-code,
            :$entry-id,
            :$date,
            :$price,
            :$quantity
        );

=head DESCRIPTION

=begin description
C<Hodling::Basis::Lot> contains parameterized roles in
object variant style, so as to differentiate between
I<named> (C<Hodling::Basis::Lot::Named>) and I<unnamed>
(C<Hodling::Basis::Lot::Unnamed>) lots.

When Tantum credits the Assets silo, I<named> lots are B<not> intermixed
with I<unnamed> lots. I<Named> lots can only be debited and credited by
specifying the proper lot name using the TXN named lot syntax.
=end description

Example TXN postings with a named lot of C<mtl-summer>:

    --  debit MontréalSafe, storing amount in a named lot
    Assets:Personal:MontréalSafe        $7.00 CAD → [mtl-summer]
    --  credit MontréalSafe, taking amount from named lot
    Assets:Personal:MontréalSafe       -$7.00 CAD ← [mtl-summer]

Example TXN postings with an unnamed lot:

    --  debit MontréalSafe
    Assets:Personal:MontréalSafe        $7.00 CAD
    --  credit MontréalSafe
    Assets:Personal:MontréalSafe       -$7.00 CAD
=end pod

# end p6doc }}}

role Hodling::Basis::Lot::Named[AssetCode:D $asset-code] {...}
role Hodling::Basis::Lot::Unnamed[AssetCode:D $asset-code] {...}

# class Hodling::Basis::Lot {{{

class Hodling::Basis::Lot
{
    has Entry::ID:D $.entry-id is required;
    has Date:D $.date is required;
    has Price:D $.price is required;
    has Quantity:D $.quantity is required;

    proto method new(|)
    {*}

    multi method new(
        AssetCode:D :$asset-code!,
        *%opts (
            Entry::ID:D :entry-id($)!,
            Date:D :date($)!,
            Price:D :price($)!,
            Quantity:D :quantity($)!,
            VarName:D :name($)!
        )
        --> Hodling::Basis::Lot::Named[$asset-code]
    )
    {
        Hodling::Basis::Lot::Named[$asset-code].bless(|%opts);
    }

    multi method new(
        AssetCode:D :$asset-code!,
        *%opts (
            Entry::ID:D :entry-id($)!,
            Date:D :date($)!,
            Price:D :price($)!,
            Quantity:D :quantity($)!
        )
        --> Hodling::Basis::Lot::Unnamed[$asset-code]
    )
    {
        Hodling::Basis::Lot::Unnamed[$asset-code].bless(|%opts);
    }
}

# end class Hodling::Basis::Lot }}}
# role Hodling::Basis::Lot::Named {{{

role Hodling::Basis::Lot::Named[AssetCode:D $asset-code]
{
    also is Hodling::Basis::Lot;

    has AssetCode:D $!asset-code = $asset-code;
    has VarName:D $.name is required;

    method asset-code(::?CLASS:D: --> AssetCode:D)
    {
        my AssetCode:D $asset-code = $!asset-code;
    }
}

# end role Hodling::Basis::Lot::Named }}}
# role Hodling::Basis::Lot::Unnamed {{{

role Hodling::Basis::Lot::Unnamed[AssetCode:D $asset-code]
{
    also is Hodling::Basis::Lot;

    has AssetCode:D $!asset-code = $asset-code;

    method asset-code(::?CLASS:D: --> AssetCode:D)
    {
        my AssetCode:D $asset-code = $!asset-code;
    }
}

# end role Hodling::Basis::Lot::Unnamed }}}

# vim: set filetype=raku foldmethod=marker foldlevel=0:
