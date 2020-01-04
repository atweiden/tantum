use v6;
use Tantum::Types;
use TXN::Parser::Actions;
use TXN::Parser::Grammar;
use TXN::Parser::Types;
unit class Config::Utils;

# method gen-asset-code {{{

method gen-asset-code(Str:D $s where .so --> AssetCode:D)
{
    my AssetCode:D $asset-code = $s;
}

# end method gen-asset-code }}}
# method gen-costing {{{

method gen-costing(Str:D $s where .so --> Costing:D)
{
    my Costing:D $costing = ::($s.uc);
}

# end method gen-costing }}}
# method gen-date {{{

method gen-date(Str:D $d where .so --> Date:D)
{
    my TXN::Parser::Actions $actions .= new;
    my Date:D $date =
        TXN::Parser::Grammar.parse($d, :rule<date:full-date>, :$actions).made;
}

# end method gen-date }}}
# method gen-date-range {{{

multi method gen-date-range(Str:D $s where .so --> Range:D)
{
    my Str:D ($d1, $d2) = $s.split('..').map({ .trim });
    my Range:D $date-range = gen-date-range($d1, $d2);
}

multi sub gen-date-range('*', '*' --> Range:D)
{
    my Range:D $date-range = * .. *;
}

multi sub gen-date-range(
    '*',
    Str:D $d2 where { TXN::Parser::Grammar.parse($_, :rule<date:full-date>) }
    --> Range:D
)
{
    my Date:D $b = Config::Utils.gen-date($d2);
    my Range:D $date-range = * .. $b;
}

multi sub gen-date-range(
    Str:D $d1 where { TXN::Parser::Grammar.parse($_, :rule<date:full-date>) },
    '*'
    --> Range:D
)
{
    my Date:D $a = Config::Utils.gen-date($d1);
    my Range:D $date-range = $a .. *;
}

multi sub gen-date-range(
    Str:D $d1 where { TXN::Parser::Grammar.parse($_, :rule<date:full-date>) },
    Str:D $d2 where { TXN::Parser::Grammar.parse($_, :rule<date:full-date>) }
    --> Range:D
)
{
    my Date:D $a = Config::Utils.gen-date($d1);
    my Date:D $b = Config::Utils.gen-date($d2);
    my Range:D $date-range = $a .. $b;
}

# end method gen-date-range }}}
# method gen-silo {{{

method gen-silo(Str:D $s where .so --> Silo:D)
{
    my Silo:D $silo = ::($s.uc);
}

# end method gen-silo }}}
# method gen-var-name {{{

method gen-var-name(Str:D $s where .so --> VarName:D)
{
    my VarName:D $var-name = $s;
}

# end method gen-var-name }}}
# method gen-var-name-bare {{{

method gen-var-name-bare(Str:D $s where .so --> VarNameBare:D)
{
    my VarNameBare:D $var-name-bare = $s;
}

# end method gen-var-name }}}
# method to-string {{{

method to-string(Range:D $r --> Str:D)
{
    my Str:D $min = to-string($r.min);
    my Str:D $max = to-string($r.max);
    my Str:D $s = sprintf(Q{%s .. %s}, $min, $max);
}

multi sub to-string(Inf --> Str:D)
{
    my Str:D $s = '*';
}

multi sub to-string(-Inf --> Str:D)
{
    my Str:D $s = '*';
}

multi sub to-string($v --> Str:D)
{
    my Str:D $s = ~$v;
}

# end method to-string }}}

# vim: set filetype=raku foldmethod=marker foldlevel=0:
