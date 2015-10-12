use v6;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::COA::Acct;

has AcctName $.name;
has VarName @.path;

# which assets were handled?
has AssetCode:D @.assets_handled;                         # Wallet.ls_assets();

# which UUIDs were handled?
has Array[UUID:D] %.entry_uuids_by_asset{AssetCode};      # Wallet.ls_assets_with_uuids();
has UUID:D @.entry_uuids_handled;                         # Wallet.ls_uuids();
has Array[UUID:D] %.posting_uuids_by_asset{AssetCode};    # Wallet.ls_assets_with_uuids(:posting);
has UUID:D @.posting_uuids_handled;                       # Wallet.ls_uuids(:posting);

# vim: ft=perl6
