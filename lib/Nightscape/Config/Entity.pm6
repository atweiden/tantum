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
    Str:D :$code! where .so,
    Str:D :$scene-file! where .so,
    :@account,
    :@asset,
    Str :$base-costing,
    Str :$base-currency,
    Date :$fiscal-year-end,
    Str :$name,
    Str :$open
    --> Nil
)
{
    $!code = Nightscape::Config::Utils.gen-var-name-bare($code);
    @!account = Nightscape::Config::Utils.gen-settings(:@account)
        if @account;
    @!asset = Nightscape::Config::Utils.gen-settings(:@asset, :$scene-file)
        if @asset;
    $!base-costing = Nightscape::Config::Utils.gen-costing($base-costing)
        if $base-costing;
    $!base-currency = Nightscape::Config::Utils.gen-asset-code($base-currency)
        if $base-currency;
    $!fiscal-year-end = $fiscal-year-end
        if $fiscal-year-end;
    $!name = Nightscape::Config::Utils.gen-var-name($name)
        if $name;
    $!open = Nightscape::Config::Utils.gen-date-range($open)
        if $open;
}

# end submethod BUILD }}}
# method new {{{

multi method new(
    *%opts (
        Str:D :code($)! where .so,
        Str:D :scene-file($)! where .so,
        :account(@),
        :asset(@),
        Str :base-costing($),
        Str :base-currency($),
        Date :fiscal-year-end($),
        Str :name($),
        Str :open($)
    )
    --> Nightscape::Config::Entity:D
)
{
    self.bless(|%opts);
}

multi method new(*% --> Nil)
{
    die(X::Nightscape::Config::Entity::Malformed.new);
}

# end method new }}}
# method hash {{{

method hash(::?CLASS:D: --> Hash:D)
{
    my %hash;
    %hash<code> = $.code;
    %hash<account> = @.account.hyper.map({ .hash }).Array if @.account;
    %hash<asset> = @.asset.hyper.map({ .hash }).Array if @.asset;
    %hash<base-costing> = $.base-costing if $.base-costing;
    %hash<base-currency> = $.base-currency if $.base-currency;
    %hash<fiscal-year-end> = $.fiscal-year-end if $.fiscal-year-end;
    %hash<name> = $.name if $.name;
    %hash<open> = Nightscape::Config::Utils.to-string($.open) if $.open;
    %hash;
}

# end method hash }}}
# sub gen-settings {{{

multi sub gen-settings(
    :@account!
    --> Array[Nightscape::Config::Account:D]
)
{
    my Nightscape::Config::Account:D @a =
        @account.hyper.map(-> %toml {
            Nightscape::Config::Account.new(|%toml)
        });
}

multi sub gen-settings(
    :@asset!,
    :$scene-file!
    --> Array[Nightscape::Config::Asset:D]
)
{
    my Nightscape::Config::Asset:D @a =
        @asset.hyper.map(-> %toml {
            Nightscape::Config::Asset.new(|%toml, :$scene-file)
        });
}

# end sub gen-settings }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
