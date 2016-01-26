use v6;
use Nightscape::Entity::TXN::ModHolding;
use Nightscape::Entity::TXN::ModWallet;
use Nightscape::Types;
unit class Nightscape::Entity::TXN;

# parent entity
has VarName $.entity is required;

# causal EntryID
has EntryID $.entry-id is required;

# transaction drift (error margin)
has FatRat $.drift = self.get-drift.keys[0];

# holdings acquisitions and expenditures indexed by asset, in entry
has Nightscape::Entity::TXN::ModHolding %.mod-holdings{AssetCode};

# wallet balance modification instructions per posting, in entry
has Nightscape::Entity::TXN::ModWallet @.mod-wallet is required;

# calculate drift (error margin) present in this TXN's ModWallet array
method get-drift(
    Nightscape::Entity::TXN::ModWallet:D :@mod-wallet is readonly =
        @.mod-wallet
) returns Hash[Hash[FatRat:D,AcctName:D],FatRat:D]
{
    my Hash[FatRat:D,AcctName:D] %drift{FatRat:D};
    my FatRat:D $drift = FatRat(0.0);
    my FatRat:D %raw-value-by-acct-name{AcctName:D};

    # Assets + Expenses = Income + Liabilities + Equity
    my Int %multiplier{Silo} =
        ::(ASSETS) => 1,
        ::(EXPENSES) => 1,
        ::(INCOME) => -1,
        ::(LIABILITIES) => -1,
        ::(EQUITY) => -1;

    for @mod-wallet -> $mod-wallet
    {
        # get AcctName
        my AcctName $acct-name = $mod-wallet.get-acct-name;

        # get Silo
        my Silo $silo = $mod-wallet.silo;

        # get subtotal raw value
        my FatRat $raw-value = $mod-wallet.get-raw-value;

        # add subtotal raw value to causal acct name index
        %raw-value-by-acct-name{$acct-name} += $raw-value;

        # add subtotal raw value to drift
        $drift += $raw-value * %multiplier{$silo};
    }

    %drift{$drift} = $%raw-value-by-acct-name;
    %drift;
}

# vim: ft=perl6
