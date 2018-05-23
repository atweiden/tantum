use v6;
use Nightscape::Dx::Account;
use TXN::Parser::Types;

class Nightscape::Dx::Coa
{
    # defaults to one account per C<Silo>
    has Account:D %.account{Silo:D} =
        Silo::.keys.hyper.map({ ::($_) }) Z=> Account.new xx Silo::.keys.elems;

    method clone(::?CLASS:D: --> Nightscape::Dx::Coa:D)
    {
        my Account:D %account{Silo:D} =
            %.account.kv.hyper.map(-> Silo:D $silo, Account:D $account {
                $silo => $account.clone
            });
        my Nightscape::Dx::Coa $coa .= new(:%account);
    }

    method in-account(
        Account:D $account,
        *@subaccount-name
        --> Account:D
    ) is rw
    {
        in-account($account, @subaccount-name);
    }

    multi sub in-account(
        Account:D $account,
        *@ (
            VarName:D $subaccount-name where { $account.subaccount{$_}:exists },
            *@tail
        )
        --> Account:D
    ) is rw
    {
        my Account:D $subaccount := $account.subaccount{$subaccount-name};
        my VarName:D @subaccount = @tail;
        in-account($subaccount, @subaccount);
    }

    multi sub in-account(
        Account:D $account,
        *@s (
            VarName:D $subaccount-name,
            *@
        )
        --> Account:D
    ) is rw
    {
        $account.mksubaccount($subaccount-name);
        my VarName:D @subaccount = @s;
        in-account($account, @subaccount);
    }

    multi sub in-account(
        Account:D $account,
        *@
        --> Account:D
    ) is rw
    {
        $account;
    }
}

sub EXPORT(--> Map:D)
{
    my %EXPORT = 'Coa' => Nightscape::Dx::Coa;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
