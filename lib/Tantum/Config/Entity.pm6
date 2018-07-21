use v6;
use Tantum::Config::Account;
use Tantum::Config::Asset;
use Tantum::Config::Utils;
use Tantum::Types;
use TXN::Parser::Types;
use X::Tantum::Config;
unit class Config::Entity;

# class attributes {{{

has VarNameBare:D $!code is required;
has Config::Account @!account;
has Config::Asset @!asset;
has Costing $!base-costing;
has AssetCode $!base-currency;
has Date $!fiscal-year-end;
has VarName $!name;
has Range $!open;

# --- accessor {{{

method account(::?CLASS:D:) { @!account }
method asset(::?CLASS:D:) { @!asset }
method base-costing(::?CLASS:D:) { $!base-costing }
method base-currency(::?CLASS:D:) { $!base-currency }
method code(::?CLASS:D:) { $!code }
method fiscal-year-end(::?CLASS:D:) { $!fiscal-year-end }
method name(::?CLASS:D:) { $!name }
method open(::?CLASS:D:) { $!open }

# --- end accessor }}}

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
    $!code = Config::Utils.gen-var-name-bare($code);
    @!account = Config::Utils.gen-settings(:@account)
        if @account;
    @!asset = Config::Utils.gen-settings(:@asset, :$scene-file)
        if @asset;
    $!base-costing = Config::Utils.gen-costing($base-costing)
        if $base-costing;
    $!base-currency = Config::Utils.gen-asset-code($base-currency)
        if $base-currency;
    $!fiscal-year-end = $fiscal-year-end
        if $fiscal-year-end;
    $!name = Config::Utils.gen-var-name($name)
        if $name;
    $!open = Config::Utils.gen-date-range($open)
        if $open;
}

# end submethod BUILD }}}
# method new {{{

proto method new(|)
{*}

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
    --> Config::Entity:D
)
{
    self.bless(|%opts);
}

multi method new(*% --> Nil)
{
    die(X::Tantum::Config::Entity::Malformed.new);
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
    %hash<open> = Config::Utils.to-string($.open) if $.open;
    %hash;
}

# end method hash }}}
# sub gen-settings {{{

multi sub gen-settings(
    :@account!
    --> Array[Config::Account:D]
)
{
    my Config::Account:D @a =
        @account.hyper.map(-> %toml {
            Config::Account.new(|%toml)
        });
}

multi sub gen-settings(
    :@asset!,
    :$scene-file!
    --> Array[Config::Asset:D]
)
{
    my Config::Asset:D @a =
        @asset.hyper.map(-> %toml {
            Config::Asset.new(|%toml, :$scene-file)
        });
}

# end sub gen-settings }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
