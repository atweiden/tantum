use v6;
use Nightscape::Config::Pricesheet;
use Nightscape::Types;
unit class Nightscape::Config;

has Str $.config_file = "%*ENV<HOME>/.config/nightscape/config.toml";
has Str $.data_dir = "%*ENV<HOME>/.nightscape";
has Str $.log_dir = "$!data_dir/logs";
has Str $.price_dir = "$!data_dir/prices";
has AssetCode $.base_currency is rw;
has Nightscape::Config::Pricesheet %.assets{AssetCode} is rw;
has %.entities is rw;

#  %.assets
#  ========
#
#  self.assets = Pricesheets indexed by asset code
#                       |
# +----------------------------------------------+
# |     self.assets<BTC> is a Pricesheet         |
# |                     |                        |
# |        +-----------------------------------+ |
# |        | Each Pricesheet is a              | |
# |        | C<hash of Prices indexed by Date> | |
# |        | indexed by asset code             | |
# |        |                                   | |
# |        |        +------------------------+ | |
# |        |        |                        | | |
# { BTC => { USD => { "2014-01-01" => 770.44 } } }
#    |        |             |            |
#  (Code)   (Code)        (Date)      (Price)
#
# ex: $nightscape.conf.assets<BTC>.prices<USD><2014-01-01>
#
#

# filter asset price data from unvalidated %toml config
method detoml_assets(%toml)
{
    my VarName $assets_header;
    %toml.map({
        $assets_header = $/.orig.Str if $_.keys ~~ m:i / ^assets /;
    });

    if $assets_header
    {
        return %toml{$assets_header};
    }
    else
    {
        return Nil;
    }
}

# filter entities from unvalidated %toml config
method detoml_entities(%toml)
{
    my VarName @entities_found;
    use Nightscape::Parser::Grammar;
    %toml.map({
        if my $parsed_section =
            Nightscape::Parser::Grammar.parse($_.keys, :rule<account_sub>)
        {
            push @entities_found, $parsed_section.orig.Str
                unless Nightscape::Parser::Grammar.parse($parsed_section.orig,
                                                         :rule<reserved>);
        }
    });

    my %entities_found;
    for @entities_found -> $entity_found
    {
        %entities_found{$entity_found} = %toml{$entity_found};
    }
    %entities_found;
}

# return base-currency of entity
# if not configured for entity, return toplevel base-currency
# if toplevel base-currency not configured, exit with an error
method get_base_currency(VarName $entity) returns AssetCode
{
    if my $entity_base_currency = self.entities{$entity}<base-currency>
    {
        return $entity_base_currency;
    }
    elsif my $toplevel_base_currency = self.base_currency
    {
        return $toplevel_base_currency;
    }
    else
    {
        my $c = self.config_file;
        die qq:to/EOF/;
        Sorry, could not find base-currency for 「$entity」

        Please check that the entity is configured with a base currency,
        or that the config file contains a toplevel base-currency
        directive.

        entity: 「$entity」
        config file: 「$c」
        EOF
    }
}

# return date-price hash by resolving price-file config option (NYI)
method !read_price_file(:$price_file!) returns Hash[Price,Date]
{
    say "Reading price file: $price_file…";
}

# return Pricesheet from unvalidated <Assets>{$code}<Prices> config
method gen_pricesheet(:%prices!) returns Nightscape::Config::Pricesheet
{
    # incoming: {
    #             :USD(
    #                  :2014-01-01(876.54),
    #                  :2014-01-02(765.43),
    #                  :price-file("path/to/usd-prices")
    #                 ),
    #             :EUR(
    #                  :2014-01-01(500.00),
    #                  :2014-01-02(400.00),
    #                  :price-file("path/to/eur-prices")
    #                 )
    #           }<>
    #
    # merges price-file directives if price-file given...
    #
    # outgoing: {
    #             Nightscape::Config::Pricesheet.new(
    #               :prices(
    #                   :USD(
    #                       Date.new("2014-01-01") => 876.54,
    #                       Date.new("2014-01-02") => 765.43,
    #                       Date.new("2014-01-03") => 654.32,    # from price-file
    #                       Date.new("2014-01-04") => 543.21     # from price-file
    #                   ),
    #                   :EUR(
    #                       Date.new("2014-01-01") => 500.00,
    #                       Date.new("2014-01-02") => 400.00,
    #                       Date.new("2014-01-03") => 300.00,    # from price-file
    #                       Date.new("2014-01-04") => 200.00     # from price-file
    #                   )
    #               )
    #             )
    #           }<>

    my Nightscape::Config::Pricesheet $pricesheet;
    for %prices.kv -> $asset, $rest
    {
        my Price %dates_and_prices{Date};
        my Price %dates_and_prices_from_file{Date};

        # gather date-price pairs from toplevel Currencies config section
        $rest.keys.grep({
            Date.new($_) ~~ Date
        }).map({
            %dates_and_prices{Date.new($_)} = $rest{Date.new($_)}
        });

        # gather date-price pairs from price-file if it exists
        my Str $price_file;
        $rest.keys.grep({
            / 'price-file' /
        }).map({
            $price_file = $rest{$_}
        });
        if $price_file
        {
            # if price-file directive given, check that the file exists
            # TODO: if price-file is given as relative path, prepend to it self.currencies_dir
            if $price_file.IO.e
            {
                %dates_and_prices_from_file = self.read_price_file(
                    :$price_file
                );
            }
            else
            {
                die "Sorry, could not locate price file at 「$price_file」";
            }
        }

        # merge %dates_and_prices_from_file with %dates_and_prices,
        # with values from %dates_and_prices keys overwriting
        # values from equivalent %dates_and_prices_from_file keys
        my Price %xe{Date} = (%dates_and_prices_from_file, %dates_and_prices);
        $pricesheet = Nightscape::Config::Pricesheet.new(
            prices => %($asset => %xe)
        );
    }
    $pricesheet;
}

# given posting asset code (aux), base asset code (base), and a date,
# return price of aux in terms of base on date
method getprice(
    AssetCode :$aux!,
    AssetCode :$base!,
    Date :$date!
) returns Price
{
    # in-journal > tag-specific > entity-specific > toplevel
    # if tag-specific
    # elsif entity-specific
    # elsif toplevel
    # else error
    self.assets{$aux}.prices{$base}{$date};
}

# vim: ft=perl6
