use v6;
use Tantum::Dx::Account;
use TXN::Parser::Types;
unit class Coa;

# defaults to one account per C<Silo>
has Account:D %.account{Silo:D} =
    Silo::.keys.map(-> Str:D $key { ::($key) }) Z=>
        Account.new xx Silo::.keys.elems;

method clone(::?CLASS:D: --> Coa:D)
{
    my Account:D %account{Silo:D} =
        %.account.kv.map(-> Silo:D $silo, Account:D $account {
            $silo => $account.clone
        });
    my Coa $coa .= new(:%account);
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

# vim: set filetype=raku foldmethod=marker foldlevel=0:
