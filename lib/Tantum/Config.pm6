use v6;
use Config::TOML;
use File::Path::Resolve;
use File::Presence;
use Tantum::Config::Account;
use Tantum::Config::Asset;
use Tantum::Config::Entity;
use Tantum::Config::Ledger;
use Tantum::Config::Utils;
use Tantum::Types;
use TXN::Parser::Types;
use X::Tantum::Config;
unit class Config;

# class attributes {{{

# --- scene {{{

has Config::Ledger:D @.ledger is required;

my Costing:D $default-base-costing = FIFO;
has Costing:D $.base-costing = $default-base-costing;

my AssetCode:D $default-base-currency = 'USD';
has AssetCode:D $.base-currency = $default-base-currency;

my Str:D $now-year-end = sprintf(Q{%s-12-31}, now.Date.year);
my Date:D $default-fiscal-year-end = Date.new($now-year-end);
has Date:D $.fiscal-year-end = $default-fiscal-year-end;

has Config::Account:D @.account;
has Config::Asset:D @.asset;
has Config::Entity:D @.entity;

# --- end scene }}}
# --- setup {{{

# application settings
has AbsolutePath:D $.app-dir is required;
has AbsolutePath:D $.app-file is required;
has AbsolutePath:D $.log-dir is required;
has AbsolutePath:D $.pkg-dir is required;
has AbsolutePath:D $.price-dir is required;
my AbsolutePath:D $default-app-dir =
    sprintf(Q{%s/.config/tantum}, $*HOME);
my AbsolutePath:D $default-log-dir =
    sprintf(Q{%s/log}, $default-app-dir);
my AbsolutePath:D $default-pkg-dir =
    sprintf(Q{%s/pkg}, $default-app-dir);
my AbsolutePath:D $default-price-dir =
    sprintf(Q{%s/prices}, $default-app-dir);
my AbsolutePath:D $default-app-file =
    sprintf(Q{%s/tantum.toml}, $default-app-dir);

# scene settings
has AbsolutePath:D $.scene-dir is required;
has AbsolutePath:D $.scene-file is required;
my AbsolutePath:D $default-scene-dir =
    sprintf(Q{%s/.tantum}, $*CWD);
my AbsolutePath:D $default-scene-file =
    sprintf(Q{%s/scene.toml}, $default-scene-dir);

# --- end setup }}}

# end class attributes }}}

# submethod BUILD {{{

multi submethod BUILD(
    Str :$app-dir,
    Str :$app-file,
    Str :$log-dir,
    Str :$pkg-dir,
    Str :$price-dir,
    Str :$scene-dir,
    Str :$scene-file,
    :$base-costing,
    :$base-currency,
    :$fiscal-year-end,
    :@account,
    :@asset,
    :@entity,
    :@ledger
    --> Nil
)
{
    self.BUILD(
        'app-file',
        [$default-app-file, $app-file],
        [$default-app-dir, $app-dir],
        [$default-log-dir, $log-dir],
        [$default-pkg-dir, $pkg-dir],
        [$default-price-dir, $price-dir],
        [$default-scene-dir, $scene-dir],
        [$default-scene-file, $scene-file]
    );
    my %app = from-toml(:file($!app-file));
    self.BUILD(
        'dirs',
        [$default-app-dir, %app<app-dir>, $app-dir],
        [$default-log-dir, %app<log-dir>, $log-dir],
        [$default-pkg-dir, %app<pkg-dir>, $pkg-dir],
        [$default-price-dir, %app<price-dir>, $price-dir],
        [$default-scene-dir, %app<scene-dir>, $scene-dir]
    );
    self.BUILD(
        'scene-file',
        [$default-scene-file, %app<scene-file>, $scene-file],
        [$base-costing, $default-base-costing],
        [$base-currency, $default-base-currency],
        [$fiscal-year-end, $default-fiscal-year-end],
        @account,
        @asset,
        @entity,
        @ledger
    );
    my %scene = from-toml(:file($!scene-file));
    self.BUILD(
        'attr',
        [@ledger, %scene<ledger>],
        [@account, %scene<account>],
        [@asset, %scene<asset>],
        [@entity, %scene<entity>],
        [$base-costing, %scene<base-costing>],
        [$base-currency, %scene<base-currency>],
        [$fiscal-year-end, %scene<fiscal-year-end>]
    );
}

multi submethod BUILD(
    'app-file',
    @app-file ($default-app-file, $app-file),
    @app-dir ($default-app-dir, $app-dir),
    @log-dir ($default-log-dir, $log-dir),
    @pkg-dir ($default-pkg-dir, $pkg-dir),
    @price-dir ($default-price-dir, $price-dir),
    @scene-dir ($default-scene-dir, $scene-dir),
    @scene-file ($default-scene-file, $scene-file)
    --> Nil
)
{
    # if option C<app-file> is passed to instantiate C<Config>, use that,
    # otherwise use default
    $!app-file = resolve-path(|@app-file);
    # write TOML to C<$!app-file> if C<$!app-file> DNE
    my %app-file-content =
        :app-dir(resolve-path(|@app-dir)),
        :log-dir(resolve-path(|@log-dir)),
        :pkg-dir(resolve-path(|@pkg-dir)),
        :price-dir(resolve-path(|@price-dir)),
        :scene-dir(resolve-path(|@scene-dir)),
        :scene-file(resolve-path(|@scene-file));
    my Str:D $app-file-content = to-toml(%app-file-content);
    prepare-config-file($!app-file, $app-file-content);
}

multi submethod BUILD(
    'dirs',
    @app-dir ($default-app-dir, $app-file-app-dir, $app-dir),
    @log-dir ($default-log-dir, $app-file-log-dir, $log-dir),
    @pkg-dir ($default-pkg-dir, $app-file-pkg-dir, $pkg-dir),
    @price-dir ($default-price-dir, $app-file-price-dir, $price-dir),
    @scene-dir ($default-scene-dir, $app-file-scene-dir, $scene-dir)
    --> Nil
)
{
    # options C<app-dir>, C<log-dir>, C<pkg-dir>, C<price-dir>,
    # C<scene-dir>, passed to instantiate C<Config> override settings
    # of the same name contained in C<$!app-file>
    #
    # if no setting is provided, use defaults
    $!app-dir = resolve-path(|@app-dir);
    $!log-dir = resolve-path(|@log-dir);
    $!pkg-dir = resolve-path(|@pkg-dir);
    $!price-dir = resolve-path(|@price-dir);
    $!scene-dir = resolve-path(|@scene-dir);
    prepare-config-dirs(
        $!app-dir,
        $!log-dir,
        $!pkg-dir,
        $!price-dir,
        $!scene-dir
    );
}

multi submethod BUILD(
    'scene-file',
    @scene-file ($default-scene-file, $app-file-scene-file, $scene-file),
    @base-costing ($base-costing, $default-base-costing),
    @base-currency ($base-currency, $default-base-currency),
    @fiscal-year-end ($fiscal-year-end, $default-fiscal-year-end),
    @account,
    @asset,
    @entity,
    @ledger
    --> Nil
)
{
    # if option C<scene-file> is passed to instantiate C<Config> override
    # settings of the same name contained in C<$!app-file>
    #
    # if no setting is provided, use default
    $!scene-file = resolve-path(|@scene-file);
    my %scene-file-content;
    %scene-file-content<base-costing> =
        (~$base-costing if $base-costing) // ~$default-base-costing;
    %scene-file-content<base-currency> =
        $base-currency // $default-base-currency;
    %scene-file-content<fiscal-year-end> =
        $fiscal-year-end // $default-fiscal-year-end;
    %scene-file-content<account> =
        @account.hyper.map({ .hash }).Array if @account;
    %scene-file-content<asset> =
        @asset.hyper.map({ .hash }).Array if @asset;
    %scene-file-content<entity> =
        @entity.hyper.map({ .hash }).Array if @entity;
    %scene-file-content<ledger> =
        @ledger.hyper.map({ .hash }).Array if @ledger;
    my Str:D $scene-file-content = to-toml(%scene-file-content);
    prepare-config-file($!scene-file, $scene-file-content);
}

multi submethod BUILD(
    'attr',
    @ (@ledger, @scene-file-ledger),
    @ (@account, @scene-file-account),
    @ (@asset, @scene-file-asset),
    @ (@entity, @scene-file-entity),
    @ ($base-costing, $scene-file-base-costing),
    @ ($base-currency, $scene-file-base-currency),
    @ ($fiscal-year-end, $scene-file-fiscal-year-end)
    --> Nil
)
{
    @!ledger = @ledger
        // gen-settings(:ledger(@scene-file-ledger, :$!scene-file));
    @!account = @account
        // (gen-settings(:account(@scene-file-account))
                if @scene-file-account);
    @!asset = @asset
        // (gen-settings(:asset(@scene-file-asset), :$!scene-file)
                if @scene-file-asset);
    @!entity = @entity
        // (gen-settings(:entity(@scene-file-entity), :$!scene-file)
                if @scene-file-entity);
    $!base-costing = $base-costing
        // (Config::Utils.gen-costing($scene-file-base-costing)
                if $scene-file-base-costing);
    $!base-currency = $base-currency
        // (Config::Utils.gen-asset-code($scene-file-base-currency)
                if $scene-file-base-currency);
    $!fiscal-year-end = $fiscal-year-end
        // ($scene-file-fiscal-year-end
                if $scene-file-fiscal-year-end);
}

# end submethod BUILD }}}
# method new {{{

method new(
    *%opts (
        Str :app-dir($),
        Str :app-file($),
        Str :log-dir($),
        Str :pkg-dir($),
        Str :price-dir($),
        Str :scene-dir($),
        Str :scene-file($),
        :base-costing($),
        :base-currency($),
        :fiscal-year-end($),
        :account(@),
        :asset(@),
        :entity(@),
        :ledger(@)
    )
    --> Config:D
)
{
    self.bless(|%opts);
}

# end method new }}}
# method resolve-entity-base-currency {{{

method resolve-entity-base-currency(
    ::?CLASS:D:
    VarName:D $entity-name
    --> AssetCode:D
)
{
    my AssetCode:D $resolve-entity-base-currency =
        resolve-entity-base-currency($.base-currency, $entity-name, @.entity);
}

multi sub resolve-entity-base-currency(
    AssetCode:D $config-base-currency,
    VarName:D $entity-name,
    Config::Entity:D @entity where { .first({ .code eq $entity-name }).so }
    --> AssetCode:D
)
{
    my Config::Entity:D $entity = @entity.first({ .code eq $entity-name });
    my AssetCode:D $resolve-entity-base-currency =
        resolve-entity-base-currency(
            $config-base-currency,
            $entity.base-currency
        );
}

# no matching entity found
multi sub resolve-entity-base-currency(
    AssetCode:D $config-base-currency,
    VarName:D $entity-name,
    Config::Entity:D @entity
    --> AssetCode:D
)
{
    my AssetCode:D $resolve-entity-base-currency = $config-base-currency;
}

multi sub resolve-entity-base-currency(
    AssetCode:D $config-base-currency,
    AssetCode:D $entity-base-currency where .so
    --> AssetCode:D
)
{
    my AssetCode:D $resolve-entity-base-currency = $entity-base-currency;
}

# C<$entity-base-currency> not present
multi sub resolve-entity-base-currency(
    AssetCode:D $config-base-currency,
    AssetCode $entity-base-currency
    --> AssetCode:D
)
{
    my AssetCode:D $resolve-entity-base-currency = $config-base-currency;
}

# end method resolve-entity-base-currency }}}
# sub gen-settings {{{

multi sub gen-settings(
    :@account!
    --> Array[Config::Account:D]
)
{
    my Config::Account:D @a =
        @account.hyper.map(-> %toml {
            Config::Account.new(|%toml)
        });
}

multi sub gen-settings(
    :@asset!,
    :$scene-file!
    --> Array[Config::Asset:D]
)
{
    my Config::Asset:D @a =
        @asset.hyper.map(-> %toml {
            Config::Asset.new(|%toml, :$scene-file)
        });
}

multi sub gen-settings(
    :@entity!,
    :$scene-file!
    --> Array[Config::Entity:D]
)
{
    my Config::Entity:D @a =
        @entity.hyper.map(-> %toml {
            Config::Entity.new(|%toml, :$scene-file)
        });
}

# ledger specified
multi sub gen-settings(
    :@ledger!,
    :$scene-file!
    --> Array[Config::Ledger:D]
)
{
    my Config::Ledger:D @a =
        @ledger.hyper.map(-> %toml {
            Config::Ledger.new(|%toml, :$scene-file)
        });
}

# ledger unspecified
multi sub gen-settings(
    :$ledger!
    --> Nil
)
{
    die(X::Tantum::Config::Ledger::Missing.new);
}

# end sub gen-settings }}}
# sub prepare-config-dirs {{{

sub prepare-config-dirs(*@config-dir --> Nil)
{
    @config-dir.map(-> Str:D $config-dir {
        prepare-config-dir($config-dir)
    });
}

multi sub prepare-config-dir(
    Str:D $config-dir where .so
    --> Nil
)
{
    my Bool:D %show{Str:D} = File::Presence.show($config-dir);
    prepare-config-dir($config-dir, %show);
}

multi sub prepare-config-dir(
    Str:D $config-dir,
    % (
        Bool:D :d($)!,
        Bool:D :e($)! where .not,
        Bool:D :f($)!,
        Bool:D :r($)!,
        Bool:D :w($)!,
        Bool:D :x($)!
    )
    --> Nil
)
{
    my Str:D $text = 'Could not prepare config dir, failed to create dir';
    mkdir($config-dir)
        or die(X::Tantum::Config::Mkdir::Failed.new(:$text));
}

multi sub prepare-config-dir(
    Str:D $,
    % (
        Bool:D :d($)!,
        Bool:D :e($)!,
        Bool:D :f($)!,
        Bool:D :r($)! where .not,
        Bool:D :w($)!,
        Bool:D :x($)!
    )
    --> Nil
)
{
    die(X::Tantum::Config::PrepareConfigDir::NotReadable.new);
}

multi sub prepare-config-dir(
    Str:D $,
    % (
        Bool:D :d($)!,
        Bool:D :e($)!,
        Bool:D :f($)!,
        Bool:D :r($)!,
        Bool:D :w($)! where .not,
        Bool:D :x($)!
    )
    --> Nil
)
{
    die(X::Tantum::Config::PrepareConfigDir::NotWriteable.new);
}

multi sub prepare-config-dir(
    Str:D $,
    % (
        Bool:D :d($)! where .not,
        Bool:D :e($)!,
        Bool:D :f($)!,
        Bool:D :r($)!,
        Bool:D :w($)!,
        Bool:D :x($)!
    )
    --> Nil
)
{
    die(X::Tantum::Config::PrepareConfigDir::NotADirectory.new);
}

multi sub prepare-config-dir(
    Str:D $,
    % (
        Bool:D :d($)!,
        Bool:D :e($)!,
        Bool:D :f($)!,
        Bool:D :r($)!,
        Bool:D :w($)!,
        Bool:D :x($)!
    )
    --> Nil
)
{*}

# end sub prepare-config-dirs }}}
# sub prepare-config-file {{{

multi sub prepare-config-file(
    Str:D $config-file where .so,
    Str:D $config-file-content where .so
    --> Nil
)
{
    my Bool:D %show{Str:D} = File::Presence.show($config-file);
    prepare-config-file($config-file, $config-file-content, %show);
}

# create config file if DNE
multi sub prepare-config-file(
    Str:D $config-file,
    Str:D $config-file-content,
    % (
        Bool:D :d($)!,
        Bool:D :e($)! where .not,
        Bool:D :f($)!,
        Bool:D :r($)!,
        Bool:D :w($)!,
        Bool:D :x($)!
    )
    --> Nil
)
{
    my Str:D $config-file-basedir = $config-file.IO.dirname;
    $config-file-basedir.IO.d
        or mkdir($config-file-basedir);
    spurt($config-file, $config-file-content ~ "\n", :createonly);
}

multi sub prepare-config-file(
    Str:D $,
    Str:D $,
    % (
        Bool:D :d($)!,
        Bool:D :e($)!,
        Bool:D :f($)!,
        Bool:D :r($)! where .not,
        Bool:D :w($)!,
        Bool:D :x($)!
    )
    --> Nil
)
{
    die(X::Tantum::Config::PrepareConfigFile::NotReadable.new);
}

multi sub prepare-config-file(
    Str:D $,
    Str:D $,
    % (
        Bool:D :d($)!,
        Bool:D :e($)!,
        Bool:D :f($)!,
        Bool:D :r($)!,
        Bool:D :w($)! where .not,
        Bool:D :x($)!
    )
    --> Nil
)
{
    die(X::Tantum::Config::PrepareConfigFile::NotWriteable.new);
}

multi sub prepare-config-file(
    Str:D $,
    Str:D $,
    % (
        Bool:D :d($)!,
        Bool:D :e($)!,
        Bool:D :f($)! where .not,
        Bool:D :r($)!,
        Bool:D :w($)!,
        Bool:D :x($)!
    )
    --> Nil
)
{
    die(X::Tantum::Config::PrepareConfigFile::NotAFile.new);
}

multi sub prepare-config-file(
    Str:D $,
    Str:D $,
    % (
        Bool:D :d($)!,
        Bool:D :e($)!,
        Bool:D :f($)!,
        Bool:D :r($)!,
        Bool:D :w($)!,
        Bool:D :x($)!
    )
    --> Nil
)
{*}

# end sub prepare-config-file }}}
# sub resolve-path {{{

multi sub resolve-path(
    *@ (Str:D $default, *@rest)
    --> Str:D
)
{
    my Str:D %path{Str:D};
    %path<default> = $default;
    %path<secondary> = shift(@rest) if @rest.so;
    %path<primary> = shift(@rest) if @rest.so;
    my Str:D $r = resolve-path(|%path);
    my Str:D $resolve-path = File::Path::Resolve.absolute($r);
}

multi sub resolve-path(
    Str:D :default($)! where .so,
    Str:D :secondary($)! where .so,
    Str:D :$primary! where .so
    --> Str:D
)
{
    my Str:D $resolve-path = $primary;
}

multi sub resolve-path(
    Str:D :default($)! where .so,
    Str:D :$secondary! where .so,
    Str :primary($)
    --> Str:D
)
{
    my Str:D $resolve-path = $secondary;
}

multi sub resolve-path(
    Str:D :$default! where .so,
    Str :secondary($),
    Str :primary($)
    --> Str:D
)
{
    my Str:D $resolve-path = $default;
}

# end sub resolve-path }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
