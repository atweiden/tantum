use v6;
use Nightscape::Config::Asset;
use Nightscape::Config::Entity;
use Nightscape::Types;
unit class Nightscape::Config;

# setup
has Str $.config_file = resolve_config_file();
has Str $.data_dir = "%*ENV<HOME>/.nightscape";
has Str $.log_dir = "$!data_dir/logs";
has Str $.price_dir = "$!data_dir/prices";

# base currency setting default/fallback for all entities
has AssetCode $.base_currency is rw = "USD";

# base inventory valuation method default/fallback for all assets
has Costing $.base_costing is rw = AVCO;

# asset settings parsed from config, indexed by asset code
has Nightscape::Config::Asset %.assets{AssetCode} is rw;

# entity settings parsed from config, indexed by entity name
has Nightscape::Config::Entity %.entities{VarName} is rw;

# filter asset price data from unvalidated %toml config
method detoml_assets(%toml) returns Hash[Any,AssetCode]
{
    # detect assets toml header
    my VarName $assets_header;
    %toml.map({ $assets_header = $/.orig.Str if $_.keys ~~ m:i / ^assets /; });

    # store assets found
    my %assets_found{AssetCode};
    %assets_found = %( %toml{$assets_header} ) if $assets_header;

    # assets found
    %assets_found;
}

# filter entities from unvalidated %toml config
method detoml_entities(%toml) returns Hash[Any,VarName]
{
    use Nightscape::Parser::Grammar;

    # detect entities
    my VarName @entities_found;
    %toml.map({
        if my $parsed_section = Nightscape::Parser::Grammar.parse(
            $_.keys,
            :rule<account_sub>
        )
        {
            push @entities_found, $parsed_section.orig.Str
                unless Nightscape::Parser::Grammar.parse(
                    $parsed_section.orig,
                    :rule<reserved>
                );
        }
    });

    # store entities found
    my %entities_found{VarName};
    if @entities_found
    {
        %entities_found{$_} = %toml{$_} for @entities_found;
    }

    # entities found
    %entities_found;
}

# return pricesheet from unvalidated <Assets>{$asset_code}<Prices> config
method gen_pricesheet(:%prices!) returns Hash[Hash[Price,Date],AssetCode]
{
    # incoming: {
    #               :USD(
    #                    :2014-01-01(876.54),
    #                    :2014-01-02(765.43),
    #                    :price-file("path/to/usd-prices")
    #               ),
    #               :EUR(
    #                    :2014-01-01(500.00),
    #                    :2014-01-02(400.00),
    #                    :price-file("path/to/eur-prices")
    #               )
    #           }<>
    #
    # merges price-file directives if price-file given...
    #
    # outgoing: {
    #               :USD(
    #                   Date.new("2014-01-01") => 876.54,
    #                   Date.new("2014-01-02") => 765.43,
    #                   Date.new("2014-01-03") => 654.32,    # from price-file
    #                   Date.new("2014-01-04") => 543.21     # from price-file
    #               ),
    #               :EUR(
    #                   Date.new("2014-01-01") => 500.00,
    #                   Date.new("2014-01-02") => 400.00,
    #                   Date.new("2014-01-03") => 300.00,    # from price-file
    #                   Date.new("2014-01-04") => 200.00     # from price-file
    #               )
    #           }<>

    my Hash[Price,Date] %pricesheet{AssetCode};
    for %prices.kv -> $asset_code, $date_price_pairs
    {
        my Price %dates_and_prices{Date};
        my Price %dates_and_prices_from_file{Date};

        # gather date-price pairs from toplevel Currencies config section
        $date_price_pairs.keys.grep({
            Date.new($_) ~~ Date
        }).map({
            %dates_and_prices{Date.new($_)} = $date_price_pairs{Date.new($_)}
        });

        # gather date-price pairs from price-file if it exists
        my Str $price_file;
        $date_price_pairs.keys.grep({
            /'price-file'/
        }).map({
            $price_file = $date_price_pairs{$_}
        });

        # price-file directive found?
        if $price_file
        {
            # if price-file directive given, check that the file exists
            # TODO: if price-file is given as relative path, prepend to it self.currencies_dir
            if $price_file.IO.e
            {
                %dates_and_prices_from_file = read_price_file(:$price_file);
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
        %pricesheet{$asset_code} = %xe;
    }
    %pricesheet;
}

# return instantiated asset settings
multi method gen_settings(
    AssetCode :$asset_code!,
    :$asset_data!
) returns Nightscape::Config::Asset
{
    # asset costing
    my Costing $costing;
    $costing = ::($asset_data<costing>) if $asset_data<costing>;

    # asset prices
    my Hash[Price,Date] %prices{AssetCode};
    %prices = self.gen_pricesheet( :prices($asset_data<Prices>) )
        if $asset_data<Prices>;

    # build asset settings
    Nightscape::Config::Asset.new(
        :$asset_code,
        :$costing,
        :%prices
    );
}

# return instantiated entity settings
multi method gen_settings(
    VarName :$entity_name!,
    :$entity_data!
) returns Nightscape::Config::Entity
{
    # populate entity-specific asset settings
    my Nightscape::Config::Asset %assets{AssetCode};
    my %assets_found = self.detoml_assets($entity_data);
    if %assets_found
    {
        for %assets_found.kv -> $asset_code, $asset_data
        {
            %assets{$asset_code} = self.gen_settings(
                :$asset_code,
                :$asset_data
            );
        }
    }

    # populate entity open dates
    my Range $open{Date};

    # build entity settings
    Nightscape::Config::Entity.new(
        :%assets,
        :$entity_name,
        :$open
    );
}

# return date-price hash by resolving price-file config option (NYI)
sub read_price_file(:$price_file!) returns Hash[Price,Date]
{
    say "Reading price file: $price_file…";
}

# get entity's base currency or if not present, the default base-currency
method resolve_base_currency(VarName $entity) returns AssetCode
{
    my AssetCode $base_currency;

    # do entity's settings specify base currency?
    if %!entities{$entity}<base-currency>
    {
        # use entity's configured base currency
        $base_currency = %!entities{$entity}<base-currency>
            or die qq:to/EOF/;
               Sorry, entity's base currency must be a valid AssetCode.

               Found: 「%!entities{$entity}<base-currency>」
               Suggested: "USD", "AUD", "JPY" (with surrounding double-quotes)
               EOF
    }
    # is there a default base currency?
    elsif $!base_currency
    {
        # use configured default base currency
        $base_currency = $!base_currency;
    }
    else
    {
        # error: base currency not found
        die qq:to/EOF/;
        Sorry, could not find base-currency for entity 「$entity」.

        Please check that the entity is configured with a base currency,
        or that the config file contains a toplevel base-currency
        directive.

        entity: 「$entity」
        config file: 「$!config_file」
        EOF
    }

    # base currency
    $base_currency;
}

# conf precedence: $PWD/nightscape.conf, $HOME/.nightscape.conf
sub resolve_config_file() returns Str
{
    my Str $config_file;

    # is nightscape.conf in CWD?
    if "nightscape.conf".IO.e
    {
        $config_file = "nightscape.conf";
    }
    # is nightscape.conf at $HOME/.nightscape.conf?
    elsif "%*ENV<HOME>/.nightscape.conf".IO.e
    {

        $config_file = "%*ENV<HOME>/.nightscape.conf";
    }
    else
    {
        $config_file = "%*ENV<HOME>/.nightscape/config.toml";
    }

    $config_file;
}

# get inventory costing method
method resolve_costing(
    AssetCode :$asset_code!,
    VarName :$entity_name!
) returns Costing
{
    my Costing $costing;

    # do entity's settings specify asset costing method?
    if %!entities{$entity_name}.assets{$asset_code}.costing
    {
        # use entity's declared costing method for this asset
        $costing = %!entities{$entity_name}.assets{$asset_code}.costing;
    }
    # do asset settings specify costing method?
    elsif %!assets{$asset_code}.costing
    {
        # use asset's specified costing method
        $costing = %!assets{$asset_code}.costing;
    }
    # is there a default costing method?
    elsif $!base_costing
    {
        # use default costing method
        $costing = $!base_costing;
    }
    else
    {
        # error: costing method not found
        die qq:to/EOF/;
        Sorry, could not find costing method for asset 「$asset_code」.

        Please check that the asset is configured with a costing method,
        or that the config file contains a toplevel costing directive.

        config file: 「$!config_file」
        asset: 「$asset_code」
        entity: 「$entity_name」
        EOF
    }

    $costing;
}

# given posting asset code (aux), base asset code (base), and a date,
# return price of aux in terms of base on date
method resolve_price(
    AssetCode :$aux!,
    AssetCode :$base!,
    Date :$date!,
    VarName :$entity_name
) returns Price
{
    my Price $price;

    # lookup entity-specific pricing?
    if $entity_name
    {
        # entity-specific pricing for aux asset in terms of base on date?
        if %!entities{$entity_name}.assets{$aux}.prices{$base}{$date}
        {
            # use entity-specific pricing
            $price = %!entities{$entity_name}.assets{$aux}.prices{$base}{$date};
        }
    }
    # pricing for aux asset in terms of base on date?
    elsif %!assets{$aux}.prices{$base}{$date}
    {
        # use asset pricing
        $price = %!assets{$aux}.prices{$base}{$date};
    }

    $price;
}

# vim: ft=perl6
