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
    %assets_found = %(%toml{$assets_header}) if $assets_header;

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
        if my Match $parsed_section = Nightscape::Parser::Grammar.parse(
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
            # if toml price-file is given as relative path, prepend to
            # it $.price_dir
            if $price_file.IO.is-relative
            {
                $price_file = $.price_dir, "/", $price_file;
            }

            # does price file exist?
            unless $price_file.IO.e
            {
                die "Sorry, could not locate price file at 「$price_file」";
            }

            %dates_and_prices_from_file = read_price_file(:$price_file);
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
    AssetCode:D :$asset_code!,
    :$asset_data!
) returns Nightscape::Config::Asset:D
{
    # asset costing
    my Costing $costing;
    $costing = ::($asset_data<costing>) if $asset_data<costing>;

    # asset prices
    my Hash[Price,Date] %prices{AssetCode};
    %prices = self.gen_pricesheet(:prices($asset_data<Prices>))
        if $asset_data<Prices>;

    # build asset settings
    Nightscape::Config::Asset.new(:$asset_code, :$costing, :%prices);
}

# return instantiated entity settings
multi method gen_settings(
    VarName:D :$entity_name!,
    :$entity_data!
) returns Nightscape::Config::Entity:D
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

    # populate entity-specific base costing if found
    my Costing $base_costing;
    $base_costing = $entity_data<base-costing> if $entity_data<base-costing>;

    # populate entity-specific base currency if found
    my AssetCode $base_currency;
    $base_currency = $entity_data<base-currency> if $entity_data<base-currency>;

    # TODO: populate entity open dates if found
    my Range $open{Date};

    # build entity settings
    Nightscape::Config::Entity.new(
        :%assets,
        :$base_costing,
        :$base_currency,
        :$entity_name,
        :$open
    );
}

# return date-price hash by resolving price-file config option (NYI)
sub read_price_file(Str:D :$price_file!) returns Hash[Price,Date]
{
    say "Reading price file: $price_file…";
}

# get entity's base currency or if not present, the default base-currency
method resolve_base_currency(VarName:D $entity) returns AssetCode:D
{
    my AssetCode $base_currency;

    # do entity's settings specify base currency?
    if %.entities{$entity}.base_currency
    {
        # use entity's configured base currency
        $base_currency = %.entities{$entity}.base_currency;
    }
    # is there a default base currency?
    elsif $.base_currency
    {
        # use configured default base currency
        $base_currency = $.base_currency;
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
        config file: 「$.config_file」
        EOF
    }

    # base currency
    $base_currency;
}

# conf precedence: $PWD/nightscape.conf, $HOME/.nightscape.conf, $HOME/.nightscape/config.toml
sub resolve_config_file() returns Str:D
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
    AssetCode:D :$asset_code!,
    VarName:D :$entity_name!
) returns Costing:D
{
    my Costing $costing_asset;
    my Costing $costing_entity;

    # check for asset costing method settings
    $costing_asset = try {%.assets{$asset_code}.costing};

    # check for entity-specific asset costing method settings
    $costing_entity =
        try {%.entities{$entity_name}.assets{$asset_code}.costing};

    # entity-specific asset costing method settings?
    if defined $costing_entity
    {
        # use entity-specific asset costing method settings
        $costing_entity;
    }
    # asset costing method settings?
    elsif defined $costing_asset
    {
        # use asset costing method settings
        $costing_asset;
    }
    # default costing method?
    elsif defined $.base_costing
    {
        # use default costing method settings
        $.base_costing;
    }
    else
    {
        # error: costing method not found
        die qq:to/EOF/;
        Sorry, could not find costing method for asset 「$asset_code」.

        Please check that the asset is configured with a costing method,
        or that the config file contains a toplevel base-costing
        directive.

        config file: 「$.config_file」
        asset: 「$asset_code」
        entity: 「$entity_name」
        EOF
    }
}

# given posting asset code (aux), base asset code (base), and a date,
# return price of aux in terms of base on date
method resolve_price(
    AssetCode:D :$aux!,
    AssetCode:D :$base!,
    Date:D :$date!,
    VarName :$entity_name
) returns Price:D
{
    my Price $price_asset;
    my Price $price_entity;

    # pricing for aux asset in terms of base on date
    $price_asset = try {%.assets{$aux}.prices{$base}{$date}};

    # entity-specific pricing for aux asset in terms of base on date
    if $entity_name
    {
        $price_entity =
            try {%.entities{$entity_name}.assets{$aux}.prices{$base}{$date}};
    }

    # return entity-specific asset pricing if available, else asset pricing
    $price_entity ?? $price_entity !! $price_asset;
}

# vim: ft=perl6
