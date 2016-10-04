use v6;
use Nightscape::Config::Account;
use Nightscape::Config::Asset;
use Nightscape::Config::Utils;
use Nightscape::Types;
use TXN::Parser::Types;
use X::Nightscape;
unit class Nightscape::Config::Entity;

# class attributes {{{

has VarNameBare:D $.code is required;

has Nightscape::Config::Account @.account;
has Nightscape::Config::Asset @.asset;
has Costing $.base-costing;
has AssetCode $.base-currency;
has Date $.fiscal-year-end;
has VarName $.name;
has Range $.open;

# end class attributes }}}

# submethod BUILD {{{

submethod BUILD(
    Str:D :$code! where *.so,
    Str:D :$price-dir! where *.so,
    :@account,
    :@asset,
    Str :$base-costing,
    Str :$base-currency,
    Date :$fiscal-year-end,
    Str :$name,
    Str :$open
)
{
    $!code = gen-var-name-bare($code);

    @!account = gen-settings(:@account) if @account;
    @!asset = gen-settings(:@asset, :$price-dir) if @asset;
    $!base-costing = gen-costing($base-costing) if $base-costing;
    $!base-currency = gen-asset-code($base-currency) if $base-currency;
    $!fiscal-year-end = $fiscal-year-end if $fiscal-year-end;
    $!name = gen-var-name($name) if $name;
    $!open = gen-date-range($open) if $open;
}

# end submethod BUILD }}}
# method new {{{

multi method new(
    *%opts (
        Str:D :code($)! where *.so,
        Str:D :price-dir($)! where *.so,
        :account(@),
        :asset(@),
        Str :base-costing($),
        Str :base-currency($),
        Date :fiscal-year-end($),
        Str :name($),
        Str :open($)
    )
)
{
    self.bless(|%opts);
}

multi method new(*%)
{
    die X::Nightscape::Config::Entity::Malformed.new;
}

# end method new }}}
# sub gen-settings {{{

multi sub gen-settings(:@account!) returns Array[Nightscape::Config::Account:D]
{
    my Nightscape::Config::Account:D @a =
        @account.map({ Nightscape::Config::Account.new(|$_) });
}

multi sub gen-settings(
    :@asset!,
    :$price-dir!
) returns Array[Nightscape::Config::Asset:D]
{
    my Nightscape::Config::Asset:D @a =
        @asset.map({ Nightscape::Config::Asset.new(|$_, :$price-dir) });
}

# end sub gen-settings }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
