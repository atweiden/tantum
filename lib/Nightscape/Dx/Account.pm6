use v6;
use TXN::Parser::Types;
unit class Nightscape::Dx::Account;

has Array[Rat:D] %.balance{AssetCode:D};
has Nightscape::Dx::Account:D %.subaccount{VarName:D};

method clone(::?CLASS:D: --> Nightscape::Dx::Account:D)
{
    my Array[Rat:D] %balance{AssetCode:D} =
        %.balance.kv.hyper.map(-> AssetCode:D $asset-code, Rat:D @delta {
            $asset-code => @delta.clone
        });
    my Nightscape::Dx::Account:D %subaccount{VarName:D} =
        %.subaccount.kv.hyper.map(->
            VarName:D $subaccount-name, Nightscape::Dx::Account:D $account {
                $subaccount-name => $account.clone
        });
    my Nightscape::Dx::Account $account .= new(:%balance, :%subaccount);
}

method mkbalance(::?CLASS:D: AssetCode:D $asset-code, Rat:D $delta --> Nil)
{
    push(%!balance{$asset-code}, $delta);
}

method mksubaccount(::?CLASS:D: VarName:D $subaccount-name --> Nil)
{
    %!subaccount{$subaccount-name} = Nightscape::Dx::Account.new;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
