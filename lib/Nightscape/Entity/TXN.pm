use v6;
use Nightscape::Entity::TXN::ModHolding;
use Nightscape::Entity::TXN::ModWallet;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::TXN;

# parent entity
has VarName $.entity;

# causal entry uuid
has UUID $.uuid;

# transaction drift (error margin)
has Rat $.drift = self.get_drift.keys[0];

# holdings acquisitions and expenditures indexed by asset, in entry
has Nightscape::Entity::TXN::ModHolding %.mod_holdings{AssetCode};

# wallet balance modification instructions per posting, in entry
has Nightscape::Entity::TXN::ModWallet @.mod_wallet;

# calculate drift (error margin) present in this TXN's ModWallet array
method get_drift(
    Nightscape::Entity::TXN::ModWallet:D :@mod_wallet is readonly =
        @.mod_wallet
) returns Hash[Hash[Rat:D,AcctName:D],Rat:D]
{
    my Hash[Rat:D,AcctName:D] %drift{Rat:D};
    my Rat:D $drift = 0.0;
    my Rat:D %raw_value_by_acct_name{AcctName:D};

    # Assets + Expenses = Income + Liabilities + Equity
    my Int %multiplier{Silo} =
        ::(ASSETS) => 1,
        ::(EXPENSES) => 1,
        ::(INCOME) => -1,
        ::(LIABILITIES) => -1,
        ::(EQUITY) => -1;

    for @mod_wallet -> $mod_wallet
    {
        # get AcctName
        my AcctName $acct_name = $mod_wallet.get_acct_name;

        # get Silo
        my Silo $silo = $mod_wallet.silo;

        # get subtotal raw value
        my Rat $raw_value = $mod_wallet.get_raw_value;

        # add subtotal raw value to causal acct name index
        %raw_value_by_acct_name{$acct_name} += $raw_value;

        # add subtotal raw value to drift
        $drift += $raw_value * %multiplier{$silo};
    }

    %drift{$drift} = $%raw_value_by_acct_name;
    %drift;
}

# vim: ft=perl6
