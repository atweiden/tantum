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
    Str:D :$code! where *.so(),
    Str:D :$scene-file where *.so(),
    Str :$costing,
    Str :$name,
    :%price
    --> Nil
)
{
    $!code = gen-asset-code($code);
    $!costing = gen-costing($costing) if $costing;
    $!name = gen-var-name($name) if $name;
    %!price = gen-price-sheet(%price, $scene-file) if %price;
}

# end submethod BUILD }}}
# method new {{{

multi method new(
    *%opts (
        Str:D :code($)! where *.so(),
        Str:D :scene-file($)! where *.so(),
        :price(%),
        Str :costing($),
        Str :name($)
    )
    --> Nightscape::Config::Asset:D
)
{
    self.bless(|%opts);
}

multi method new(*% --> Nil)
{
    die(X::Nightscape::Config::Asset::Malformed.new());
}

# end method new }}}
# sub gen-price-sheet {{{

sub gen-price-sheet(
    %price where *.so(),
    AbsolutePath:D $scene-file where *.so()
    --> Hash[Hash[Price:D,Date:D],AssetCode:D]
)
{
    my Hash[Price:D,Date:D] %price-sheet{AssetCode:D} =
        %price.kv.map(-> $asset-code, %asset-code-keypairs {
            my Price:D %dates-and-prices{Date:D} =
                gen-dates-and-prices(%asset-code-keypairs);
            my Price:D %dates-and-prices-from-file{Date:D} =
                gen-dates-and-prices-from-file(
                    %asset-code-keypairs,
                    $scene-file
                );

            # merge C<%dates-and-prices-from-file>
            # with C<%dates-and-prices>, with values from
            # C<%dates-and-prices> keys overwriting values from equivalent
            # C<%dates-and-prices-from-file> keys
            my Price:D %xe{Date:D} =
                |%dates-and-prices-from-file,
                |%dates-and-prices;

            my Hash[Price:D,Date:D] %h{AssetCode:D} = $asset-code => %xe;
        });
}

sub gen-dates-and-prices(
    %asset-code-keypairs where *.so()
    --> Hash[Price:D,Date:D]
)
{
    my Price:D %dates-and-prices{Date:D} =
        %asset-code-keypairs
        .grep({ TXN::Parser::Grammar.parse(.key(), :rule<date:full-date>) })
        .map({
            die(X::Nightscape::Config::Asset::Price::Malformed.new())
                unless FatRat(.value()) ~~ Price;
            Date.new(.key()) => FatRat(.value())
        });
}

multi sub gen-dates-and-prices-from-file(
    %asset-code-keypairs where *.so,
    AbsolutePath:D $scene-file where *.so()
    --> Hash[Price:D,Date:D]
)
{
    my Str $price-file =
        %asset-code-keypairs.grep({ .key().isa(Str) })
                            .first({ .key() eq 'price-file' })
                            .value();

    # gather date-price pairs from C<$price-file> if it exists
    my Price:D %dates-and-prices-from-file{Date:D} =
        gen-dates-and-prices-from-file(
            %asset-code-keypairs,
            $scene-file,
            $price-file
        );
}

multi sub gen-dates-and-prices-from-file(
    %asset-code-keypairs where *.so,
    AbsolutePath:D $scene-file where *.so(),
    Str:D $price-file where *.so
    --> Hash[Price:D,Date:D]
)
{
    # if C<$price-file> from toml is given as relative path, prepend to
    # it C<$scene-file.IO.dirname>
    #
    # this is because price-file directives can only be given within
    # the scene config file
    #
    # thus relative paths appearing within the scene config file must
    # be resolved relative to the scene config file
    my Str:D $file = $scene-file.IO.dirname() ~ '/' ~ $price-file
        if $price-file.subst(/^'~/'/, "$*HOME/").IO.is-relative();

    # resolve absolute paths potentially beginning with C<~/>
    $file = resolve-path($file);

    die(X::Nightscape::Config::Asset::PriceFile::DNERF.new())
        unless exists-readable-file($file);

    my %toml = from-toml(:$file);
    my Price:D %dates-and-prices-from-file{Date:D} = gen-price-sheet(%toml);
}

multi sub gen-dates-and-prices-from-file(
    %asset-code-keypairs where *.so,
    AbsolutePath:D $scene-file where *.so(),
    Str $price-file
    --> Hash[Price:D,Date:D]
)
{
    my Price:D %dates-and-prices-from-file{Date:D};
}

# end sub gen-price-sheet }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
