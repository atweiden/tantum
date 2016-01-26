use v6;
use Nightscape::Types;
unit class Nightscape::Entity::COA::Acct;

has AcctName $.name is required;
has VarName @.path is required;

# which assets were handled?
has AssetCode:D @.assets-handled;                          # Wallet.ls-assets();

# which IDs were handled?
has Array[EntryID:D] %.entry-ids-by-asset{AssetCode};      # Wallet.ls-assets-with-ids();
has EntryID:D @.entry-ids-handled;                         # Wallet.ls-ids();
has Array[PostingID] %.posting-ids-by-asset{AssetCode};    # Wallet.ls-assets-with-ids(:posting);
has PostingID @.posting-ids-handled;                       # Wallet.ls-ids(:posting);

# vim: ft=perl6
