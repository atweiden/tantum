use v6;
use Nightscape::Types;
unit class Nightscape::Entity::Wallet::Changeset;

# Δ ± balance
has FatRat $.balance-delta is required;

# self-referential asset code of this balance delta
has AssetCode $.balance-delta-asset-code is required;

# causal EntryID
has EntryID $.entry-id is required;

# causal PostingID
has PostingID $.posting-id is required;

# causal posting's exchange rate asset code, if given
has AssetCode $.xe-asset-code;

# causal posting's exchange rate asset quantity, if given
has Quantity $.xe-asset-quantity;

# update balance-delta in-place
method mkbalance-delta(FatRat:D :$balance-delta!, Bool :$force)
{
    # update $.balance-delta in-place
    sub init()
    {
        $!balance-delta = $balance-delta;
    }

    # was :force arg passed to the method?
    if $force
    {
        # update $.balance-delta in-place
        init();
    }
    # does $.balance-delta exist?
    elsif $.balance-delta
    {
        # error: balance-delta exists, pass :force arg to overwrite
        die "Sorry, can't overwrite existing balance-delta";
    }
    else
    {
        # update $.balance-delta in-place
        init();
    }
}

# update xe-asset-quantity in-place
method mkxeaq(Quantity:D :$xe-asset-quantity!, Bool :$force)
{
    # update $.xe-asset-quantity in-place
    sub init()
    {
        $!xe-asset-quantity = $xe-asset-quantity;
    }

    # was :force arg passed to the method?
    if $force
    {
        # update $.xe-asset-quantity in-place
        init();
    }
    # does $.xe-asset-quantity exist?
    elsif $.xe-asset-quantity
    {
        # error: xe-asset-quantity exists, pass :force arg to overwrite
        die "Sorry, can't overwrite existing xe-asset-quantity";
    }
    else
    {
        # update $.xe-asset-quantity in-place
        init();
    }
}

# vim: ft=perl6
