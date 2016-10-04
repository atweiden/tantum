use v6;
use Config::TOML;
use File::Presence;
use Nightscape::Config::Utils;
use Nightscape::Types;
use TXN::Parser::Grammar;
use TXN::Parser::Types;
use X::Nightscape;
unit class Nightscape::Config::Asset;

# class attributes {{{

has AssetCode:D $.code is required;

has Costing $.costing;
has VarName $.name;
has Hash[Price:D,Date:D] %.price{AssetCode:D};

# end class attributes }}}

# submethod BUILD {{{

submethod BUILD(
    Str:D :$code! where *.so,
    Str:D :$price-dir where *.so,
    Str :$costing,
    Str :$name,
    :%price
)
{
    $!code = gen-asset-code($code);

    $!costing = gen-costing($costing) if $costing;
    $!name = gen-var-name($name) if $name;
    %!price = gen-price-sheet(%price, $price-dir) if %price;
}

# end submethod BUILD }}}
# method new {{{

multi method new(
    *%opts (
        Str:D :code($)! where *.so,
        Str:D :price-dir($)! where *.so,
        :price(%),
        Str :costing($),
        Str :name($)
    )
)
{
    self.bless(|%opts);
}

multi method new(*%)
{
    die X::Nightscape::Config::Asset::Malformed.new;
}

# end method new }}}
# sub gen-price-sheet {{{

multi sub gen-price-sheet(
    %price where *.so,
    AbsolutePath:D $price-dir where *.so
) returns Hash[Hash[Price:D,Date:D],AssetCode:D]
{
    my Hash[Price:D,Date:D] %price-sheet{AssetCode:D};

    for %price.kv -> $asset-code, %asset-code-keypairs
    {
        my Price:D %dates-and-prices-from-file{Date:D};
        my Price:D %dates-and-prices{Date:D} =
            gen-price-sheet(%asset-code-keypairs);

        # gather date-price pairs from C<$price-file> if it exists
        my Str $price-file =
            %asset-code-keypairs.grep(*.key.isa(Str))
                                .first(*.key eq 'price-file')
                                .value;

        if $price-file
        {
            # if C<$price-file> from toml is given as relative path,
            # prepend to it C<$price-dir>
            $price-file = $price-dir ~ '/' ~ $price-file
                if $price-file.IO.is-relative;
            die unless exists-readable-file($price-file);
            %dates-and-prices-from-file =
                gen-price-sheet(from-toml(:file($price-file)));
        }

        # merge C<%dates-and-prices-from-file> with C<%dates-and-prices>,
        # with values from C<%dates-and-prices> keys overwriting values
        # from equivalent C<%dates-and-prices-from-file> keys
        my Price:D %xe{Date:D} =
            |%dates-and-prices-from-file,
            |%dates-and-prices;
        %price-sheet{$asset-code} = %xe;
    }

    %price-sheet;
}

multi sub gen-price-sheet(
    %asset-code-keypairs where *.so
) returns Hash[Price:D,Date:D]
{
    my Price:D %dates-and-prices{Date:D} = %asset-code-keypairs.grep({
        TXN::Parser::Grammar.parse(.key, :rule<date:full-date>)
    }).map({
        die X::Nightscape::Config::Asset::Price::Malformed.new
            unless FatRat(.value) ~~ Price;
        Date.new(.key) => FatRat(.value)
    });
}

# end sub gen-price-sheet }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
