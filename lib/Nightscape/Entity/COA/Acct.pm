use v6;
use Nightscape::Types;
unit class Nightscape::Entity::COA::Acct;

has AcctName $.name;
has VarName @.path;

# which assets were handled?
has AssetCode:D @.assets_handled;                            # Wallet.ls_assets();

# which IDs were handled?
has Array[EntryID:D] %.entry_ids_by_asset{AssetCode};        # Wallet.ls_assets_with_ids();
has EntryID:D @.entry_ids_handled;                           # Wallet.ls_ids();
has Array[PostingID:D] %.posting_ids_by_asset{AssetCode};    # Wallet.ls_assets_with_ids(:posting);
has PostingID:D @.posting_ids_handled;                       # Wallet.ls_ids(:posting);

# vim: ft=perl6
