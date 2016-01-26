use v6;
use Nightscape::Config::Asset;
use Nightscape::Config::Entity;
use Nightscape::Types;
unit class Nightscape::Config;

# setup
has Str $.config-file = resolve-config-file();
has Str $.data-dir = "%*ENV<HOME>/.nightscape";
has Str $.log-dir = "$!data-dir/logs";
has Str $.price-dir = "$!data-dir/prices";

# base currency setting default/fallback for all entities
has AssetCode $.base-currency is rw = "USD";

# base inventory valuation method default/fallback for all assets
has Costing $.base-costing is rw = AVCO;

# asset settings parsed from config, indexed by asset code
has Nightscape::Config::Asset %.assets{AssetCode} is rw;

# entity settings parsed from config, indexed by entity name
has Nightscape::Config::Entity %.entities{VarName} is rw;

# filter asset price data from unvalidated %toml config
method detoml-assets(%toml) returns Hash[Any,AssetCode]
{
    # find [Aa]ssets toml header (case insensitive)
    my VarName $assets-header;
    $assets-header = %toml.keys.grep(/:i ^assets/)[0];

    # store assets found
    my %assets-found{AssetCode};

    # assign assets data (under case insensitive [Aa]ssets toml header)
    %assets-found = %toml{$assets-header} if $assets-header;

    %assets-found;
}

# filter entities from unvalidated %toml config
method detoml-entities(%toml) returns Hash[Any,VarName]
{
    use TXN::Parser::Grammar;

    # detect entities
    my VarName @entities-found;
    %toml.map({
        if my Match $parsed-section = TXN::Parser::Grammar.parse(
            $_.keys,
            :rule<var-name>
        )
        {
            push @entities-found, $parsed-section.orig.Str
                unless TXN::Parser::Grammar.parse(
                    $parsed-section.orig,
                    :rule<reserved>
                );
        }
    });

    # store entities found
    my %entities-found{VarName};
    if @entities-found
    {
        %entities-found{$_} = %toml{$_} for @entities-found;
    }

    # entities found
    %entities-found;
}

# return pricesheet from unvalidated <Assets>{$asset-code}<Prices> config
method gen-pricesheet(:%prices!) returns Hash[Hash[Price,DateTime],AssetCode]
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
    #                   DateTime.new(...) => 876.54,
    #                   DateTime.new(...) => 765.43,
    #                   DateTime.new(...) => 654.32,    # from price-file
    #                   DateTime.new(...) => 543.21     # from price-file
    #               ),
    #               :EUR(
    #                   DateTime.new(...) => 500.00,
    #                   DateTime.new(...) => 400.00,
    #                   DateTime.new(...) => 300.00,    # from price-file
    #                   DateTime.new(...) => 200.00     # from price-file
    #               )
    #           }<>
    use TXN::Parser::Grammar;

    my Hash[Price,DateTime] %pricesheet{AssetCode};
    for %prices.kv -> $asset-code, $date-price-pairs
    {
        my Price %dates-and-prices{DateTime};
        my Price %dates-and-prices-from-file{DateTime};

        # gather date-price pairs from toplevel Currencies config section
        #
        # build DateTimes from TOML config containing potentially mixed
        # YYYY-MM-DD keys and RFC3339 timestamp keys
        for $date-price-pairs.keys -> $key
        {
            # convert valid YYYY-MM-DD dates to DateTime
            if TXN::Parser::Grammar.parse($key, :rule<full-date>)
            {
                my %dt = <year month day> Z=> map +*, $key.split('-');
                %dates-and-prices{DateTime.new(|%dt)} =
                    FatRat($date-price-pairs{$key});
            }
        };

        # gather date-price pairs from price-file if it exists
        my Str $price-file;
        $date-price-pairs.keys.grep(/'price-file'/).map({
            $price-file = $date-price-pairs{$_}
        });

        # price-file directive found?
        if $price-file
        {
            # if toml price-file is given as relative path, prepend to
            # it $.price-dir
            if $price-file.IO.is-relative
            {
                $price-file = $.price-dir ~ "/" ~ $price-file;
            }

            # does price file exist?
            unless $price-file.IO.e
            {
                die "Sorry, could not locate price file at 「$price-file」";
            }

            %dates-and-prices-from-file = read-price-file(:$price-file);
        }

        # merge %dates-and-prices-from-file with %dates-and-prices,
        # with values from %dates-and-prices keys overwriting
        # values from equivalent %dates-and-prices-from-file keys
        my Price %xe{DateTime} =
            (%dates-and-prices-from-file, %dates-and-prices);
        %pricesheet{$asset-code} = %xe;
    }
    %pricesheet;
}

# return instantiated asset settings
multi method gen-settings(
    AssetCode:D :$asset-code!,
    :$asset-data!
) returns Nightscape::Config::Asset:D
{
    # asset costing
    my Costing $costing;
    $costing = ::($asset-data<costing>) if $asset-data<costing>;

    # asset prices
    my Hash[Price,DateTime] %prices{AssetCode};
    %prices = self.gen-pricesheet(:prices($asset-data<Prices>))
        if $asset-data<Prices>;

    # build asset settings
    Nightscape::Config::Asset.new(:$asset-code, :$costing, :%prices);
}

# return instantiated entity settings
multi method gen-settings(
    VarName:D :$entity-name!,
    :$entity-data!
) returns Nightscape::Config::Entity:D
{
    # populate entity-specific asset settings
    my Nightscape::Config::Asset %assets{AssetCode};
    my %assets-found = self.detoml-assets($entity-data);
    if %assets-found
    {
        for %assets-found.kv -> $asset-code, $asset-data
        {
            %assets{$asset-code} = self.gen-settings(
                :$asset-code,
                :$asset-data
            );
        }
    }

    # populate entity-specific base costing if found
    my Costing $base-costing;
    $base-costing = $entity-data<base-costing> if $entity-data<base-costing>;

    # populate entity-specific base currency if found
    my AssetCode $base-currency;
    $base-currency = $entity-data<base-currency> if $entity-data<base-currency>;

    # TODO: populate entity open dates if found
    my Range $open;

    # build entity settings
    Nightscape::Config::Entity.new(
        :%assets,
        :$base-costing,
        :$base-currency,
        :$entity-name,
        :$open
    );
}


# return date-price hash by resolving price-file config option (NYI)
sub read-price-file(Str:D :$price-file!) returns Hash[Price,DateTime]
{
    say "Reading price file: $price-file…";
}

# get entity's base currency or if not present, the default base-currency
method resolve-base-currency(VarName:D $entity) returns AssetCode:D
{
    my AssetCode $base-currency;

    # do entity's settings specify base currency?
    if try {%.entities{$entity}.base-currency}
    {
        # use entity's configured base currency
        $base-currency = %.entities{$entity}.base-currency;
    }
    # is there a default base currency?
    elsif $.base-currency
    {
        # use configured default base currency
        $base-currency = $.base-currency;
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
        config file: 「$.config-file」
        EOF
    }

    # base currency
    $base-currency;
}

# conf precedence: $PWD/nightscape.conf, $HOME/.nightscape.conf, $HOME/.nightscape/config.toml
sub resolve-config-file() returns Str:D
{
    my Str $config-file;

    # is nightscape.conf in CWD?
    if "nightscape.conf".IO.e
    {
        $config-file = "nightscape.conf";
    }
    # is nightscape.conf at $HOME/.nightscape.conf?
    elsif "%*ENV<HOME>/.nightscape.conf".IO.e
    {

        $config-file = "%*ENV<HOME>/.nightscape.conf";
    }
    else
    {
        $config-file = "%*ENV<HOME>/.nightscape/config.toml";
    }

    $config-file;
}

# get inventory costing method
method resolve-costing(
    AssetCode:D :$asset-code!,
    VarName:D :$entity-name!
) returns Costing:D
{
    my Costing $costing-asset;
    my Costing $costing-entity;

    # check for asset costing method settings
    $costing-asset = try {%.assets{$asset-code}.costing};

    # check for entity-specific asset costing method settings
    $costing-entity =
        try {%.entities{$entity-name}.assets{$asset-code}.costing};

    # entity-specific asset costing method settings?
    if defined $costing-entity
    {
        # use entity-specific asset costing method settings
        $costing-entity;
    }
    # asset costing method settings?
    elsif defined $costing-asset
    {
        # use asset costing method settings
        $costing-asset;
    }
    # default costing method?
    elsif defined $.base-costing
    {
        # use default costing method settings
        $.base-costing;
    }
    else
    {
        # error: costing method not found
        die qq:to/EOF/;
        Sorry, could not find costing method for asset 「$asset-code」.

        Please check that the asset is configured with a costing method,
        or that the config file contains a toplevel base-costing
        directive.

        config file: 「$.config-file」
        asset: 「$asset-code」
        entity: 「$entity-name」
        EOF
    }
}

# given posting asset code (aux), base asset code (base), and a date,
# return price of aux in terms of base on date
method resolve-price(
    AssetCode:D :$aux!,
    AssetCode:D :$base!,
    DateTime:D :$date!,
    VarName :$entity-name
) returns Price
{
    my Price $price-asset;
    my Price $price-entity;

    # pricing for aux asset in terms of base on date
    $price-asset = try {%.assets{$aux}.prices{$base}\
        .grep({ .keys[0].year ~~ $date.year })\
        .grep({ .keys[0].month ~~ $date.month })\
        .grep({ .keys[0].day ~~ $date.day })\
        .values[0].value
    }; # %.assets{$aux}.prices{$base}{$date} fails nom 2015-10-14

    # entity-specific pricing for aux asset in terms of base on date
    if $entity-name
    {
        $price-entity =
            try {%.entities{$entity-name}.assets{$aux}.prices{$base}{$date}};
    }

    # return entity-specific asset pricing if available, else asset pricing
    $price-entity ?? $price-entity !! $price-asset;
}

# vim: ft=perl6
