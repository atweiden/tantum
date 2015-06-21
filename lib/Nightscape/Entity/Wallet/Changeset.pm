use v6;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::Wallet::Changeset;

# Δ ± balance
has Rat $.balance_delta;

# self-referential asset code of this balance delta
has AssetCode $.balance_delta_asset_code;

# causal posting's uuid
has UUID $.posting_uuid;

# causal posting's exchange rate asset code, if given
has AssetCode $.xe_asset_code;

# causal posting's exchange rate asset quantity, if given
has Rat $.xe_asset_quantity;

# vim: ft=perl6
