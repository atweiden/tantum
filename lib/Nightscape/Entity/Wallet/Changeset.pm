use v6;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::Wallet::Changeset;

# Δ ± balance
has Rat $.balance_delta;

# self-referential asset code of this balance delta
has AssetCode $.balance_delta_asset_code;

# causal entry's uuid
has UUID $.entry_uuid;

# causal posting's uuid
has UUID $.posting_uuid;

# causal posting's exchange rate asset code, if given
has AssetCode $.xe_asset_code;

# causal posting's exchange rate asset quantity, if given
has Quantity $.xe_asset_quantity;

# update xe_asset_quantity in-place
method mkxeaq(Quantity :$xe_asset_quantity!, Bool :$force)
{
    # update $.xe_asset_quantity in-place
    sub init()
    {
        $!xe_asset_quantity = $xe_asset_quantity;
    }

    # was :force arg passed to the method?
    if $force
    {
        # update $.xe_asset_quantity in-place
        init();
    }
    # does $.xe_asset_quantity exist?
    elsif $.xe_asset_quantity
    {
        # error: xe_asset_quantity exists, pass :force arg to overwrite
        die "Sorry, can't overwrite existing xe_asset_quantity";
    }
    else
    {
        # update $.xe_asset_quantity in-place
        init();
    }
}

# vim: ft=perl6
