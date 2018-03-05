use v6;
use Nightscape::Config::Utils;
use TXN::Parser::Types;
use X::Nightscape;
unit class Nightscape::Config::Account;

# class attributes {{{

has Silo:D $.silo is required;
has VarName:D $.entity is required;
has VarName:D @.path is required;

has Range $.open;

# end class attributes }}}

# submethod BUILD {{{

submethod BUILD(
    Str:D :$silo! where *.so,
    Str:D :$entity! where *.so,
    :@path! where *.so,
    Str :$open
    --> Nil
)
{
    $!silo = gen-silo($silo);
    $!entity = gen-var-name($entity);
    @!path = @path.map({ gen-var-name($_) });
    $!open = gen-date-range($open) if $open;
}

# end submethod BUILD }}}
# method new {{{

multi method new(
    *%opts (
        Str:D :silo($)! where *.so,
        Str:D :entity($)! where *.so,
        :path(@)! where *.so,
        Str :open($)
    )
    --> Nightscape::Config::Account:D
)
{
    self.bless(|%opts);
}

multi method new(*%)
{
    die(X::Nightscape::Config::Account::Malformed.new);
}

# end method new }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
