use v6;
use Tantum::Config::Utils;
use TXN::Parser::Types;
use X::Tantum::Config;
unit class Config::Account;

# class attributes {{{

has Silo:D $.silo is required;
has VarName:D $.entity is required;
has VarName:D @.path is required;
has Range $.open;

# end class attributes }}}

# submethod BUILD {{{

submethod BUILD(
    Str:D :$silo! where .so,
    Str:D :$entity! where .so,
    :@path! where .so,
    Str :$open
    --> Nil
)
{
    $!silo = Config::Utils.gen-silo($silo);
    $!entity = Config::Utils.gen-var-name($entity);
    @!path =
        @path.hyper.map(-> $path {
            Config::Utils.gen-var-name($path)
        });
    $!open = Config::Utils.gen-date-range($open) if $open;
}

# end submethod BUILD }}}
# method new {{{

multi method new(
    *%opts (
        Str:D :silo($)! where .so,
        Str:D :entity($)! where .so,
        :path(@)! where .so,
        Str :open($)
    )
    --> Config::Account:D
)
{
    self.bless(|%opts);
}

multi method new(*%)
{
    die(X::Tantum::Config::Account::Malformed.new);
}

# end method new }}}
# method hash {{{

method hash(::?CLASS:D: --> Hash:D)
{
    my %hash;
    %hash<silo> = $.silo;
    %hash<entity> = $.entity;
    %hash<path> = @.path;
    %hash<open> = Config::Utils.to-string($.open) if $.open;
    %hash;
}

# end method hash }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
