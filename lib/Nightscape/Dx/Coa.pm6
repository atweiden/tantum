use v6;
use Nightscape::Dx::Account;
use TXN::Parser::Types;
unit class Nightscape::Dx::Coa;

# defaults to one account per C<Silo>
has Nightscape::Dx::Account:D %.account{Silo:D} =
    Silo::.keys.hyper.map({ ::($_) }) Z=>
        Nightscape::Dx::Account.new xx Silo::.keys.elems;

method clone(::?CLASS:D: --> Nightscape::Dx::Coa:D)
{
    my Nightscape::Dx::Account:D %account{Silo:D} =
        %.account.kv.hyper.map(->
            Silo:D $silo, Nightscape::Dx::Account:D $account {
                $silo => $account.clone
        });
    my Nightscape::Dx::Coa $coa .= new(:%account);
}

method in-account(
    Nightscape::Dx::Account:D $account,
    *@subaccount-name
    --> Nightscape::Dx::Account:D
) is rw
{
    in-account($account, @subaccount-name);
}

multi sub in-account(
    Nightscape::Dx::Account:D $account,
    *@ (
        VarName:D $subaccount-name where { $account.subaccount{$_}:exists },
        *@tail
    )
    --> Nightscape::Dx::Account:D
) is rw
{
    my Nightscape::Dx::Account:D $subaccount :=
        $account.subaccount{$subaccount-name};
    my VarName:D @subaccount = @tail;
    in-account($subaccount, @subaccount);
}

multi sub in-account(
    Nightscape::Dx::Account:D $account,
    *@s (
        VarName:D $subaccount-name,
        *@
    )
    --> Nightscape::Dx::Account:D
) is rw
{
    $account.mksubaccount($subaccount-name);
    my VarName:D @subaccount = @s;
    in-account($account, @subaccount);
}

multi sub in-account(
    Nightscape::Dx::Account:D $account,
    *@
    --> Nightscape::Dx::Account:D
) is rw
{
    $account;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
