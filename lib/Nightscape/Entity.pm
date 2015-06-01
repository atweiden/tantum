use v6;
use Nightscape::Entity::Wallet;
use Nightscape::Entry::Posting;
use Nightscape::Types;
unit class Nightscape::Entity;

# wallets indexed by silo
has Nightscape::Entity::Wallet %.wallet{Silo} is rw;

# given a wallet, and subwallet name list, assign to the deepest subwallet
# has harmless side effect of creating new and often empty Wallet classes
sub deref(Nightscape::Entity::Wallet $wallet, *@subwallet) is rw
{
    # make $subwallet point to the same scalar container as $wallet
    my Nightscape::Entity::Wallet $subwallet := $wallet;

    # the subwallet name list
    my VarName @s = @subwallet;

    # if subwallets were given, loop through them
    while @s
    {
        # name of next deeper subwallet
        my VarName $s = @s.shift;

        # create $s if it doesn't exist
        $subwallet.subwallet{$s} = Nightscape::Entity::Wallet.new
            if !$subwallet.subwallet{$s};

        # make $subwallet point to same scalar container as its subwallet, $s
        $subwallet := $subwallet.subwallet{$s};
    }

    # deepest subwallet
    $subwallet;
}

# given a posting, dec/inc the applicable wallet balance
method do(Nightscape::Entry::Posting :$posting!)
{
    use Nightscape::Entry::Posting::Account;
    use Nightscape::Entry::Posting::Amount;

    # from Nightscape::Entry::Posting
    my Nightscape::Entry::Posting::Account $account = $posting.account;
    my Nightscape::Entry::Posting::Amount $amount = $posting.amount;
    my DecInc $decinc = $posting.decinc;

    # from Nightscape::Entry::Posting::Account
    my Silo $silo = $account.silo;
    my VarName @subwallet = $account.subaccount;

    # from Nightscape::Entry::Posting::Amount
    my AssetCode $asset_code = $amount.asset_code;
    my Quantity $asset_quantity = $amount.asset_quantity;

    # ensure $silo wallet exists
    self.wallet{$silo} = Nightscape::Entity::Wallet.new
        if !self.wallet{$silo};

    # dec/inc wallet balance
    &deref(self.wallet{$silo}, @subwallet).setbalance(
        $asset_code,
        $asset_quantity,
        $decinc
    );
}

# vim: ft=perl6
