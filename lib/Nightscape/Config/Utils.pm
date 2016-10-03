use v6;
use Nightscape::Types;
use TXN::Parser;
use TXN::Parser::Types;
unit module Nightscape::Config::Utils;

# sub gen-asset-code {{{

sub gen-asset-code(Str:D $s where *.so) is export returns AssetCode:D
{
    my AssetCode:D $asset-code = $s;
}

# end sub gen-asset-code }}}
# sub gen-costing {{{

sub gen-costing(Str:D $s where *.so) is export returns Costing:D
{
    my Costing:D $costing = ::($s.uc);
}

# end sub gen-costing }}}
# sub gen-date {{{

sub gen-date(Str:D $d where *.so) is export returns Date:D
{
    my TXN::Parser::Actions:D $actions = TXN::Parser::Actions.new;
    my Date:D $date =
        TXN::Parser::Grammar.parse($d, :rule<date:full-date>, :$actions).made;
}

# end sub gen-date }}}
# sub gen-date-range {{{

multi sub gen-date-range(Str:D $s where *.so) is export returns Range:D
{
    my Str:D ($d1, $d2) = $s.split('..')».trim;
    my Range:D $date-range = gen-date-range($d1, $d2);
}

multi sub gen-date-range('*', '*') returns Range:D
{
    my Range:D $date-range = * .. *;
}

multi sub gen-date-range(
    '*',
    Str:D $d2 where { TXN::Parser::Grammar.parse($_, :rule<date:full-date>) }
) returns Range:D
{
    my Date:D $b = gen-date($d2);
    my Range:D $date-range = * .. $b;
}

multi sub gen-date-range(
    Str:D $d1 where { TXN::Parser::Grammar.parse($_, :rule<date:full-date>) },
    '*'
) returns Range:D
{
    my Date:D $a = gen-date($d1);
    my Range:D $date-range = $a .. *;
}

multi sub gen-date-range(
    Str:D $d1 where { TXN::Parser::Grammar.parse($_, :rule<date:full-date>) },
    Str:D $d2 where { TXN::Parser::Grammar.parse($_, :rule<date:full-date>) }
) returns Range:D
{
    my Date:D $a = gen-date($d1);
    my Date:D $b = gen-date($d2);
    my Range:D $date-range = $a .. $b;
}

# end sub gen-date-range }}}
# sub gen-silo {{{

sub gen-silo(Str:D $s where *.so) is export returns Silo:D
{
    my Silo:D $silo = ::($s.uc);
}

# end sub gen-silo }}}
# sub gen-var-name {{{

sub gen-var-name(Str:D $s where *.so) is export returns VarName:D
{
    my VarName:D $var-name = $s;
}

# end sub gen-var-name }}}
# sub gen-var-name-bare {{{

sub gen-var-name-bare(Str:D $s where *.so) is export returns VarNameBare:D
{
    my VarNameBare:D $var-name-bare = $s;
}

# end sub gen-var-name }}}
# sub resolve-path {{{

sub resolve-path(Str:D $path where *.so) is export returns Str:D
{
    ~$path.subst(/^'~/'/, $*HOME ~ '/').IO.resolve;
}

# end sub resolve-path }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
