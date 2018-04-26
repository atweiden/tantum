use v6;
use Config::TOML;
use File::Path::Resolve;
use File::Presence;
use Nightscape::Config::Account;
use Nightscape::Config::Asset;
use Nightscape::Config::Entity;
use Nightscape::Config::Ledger;
use Nightscape::Config::Utils;
use Nightscape::Types;
use TXN::Parser::Types;
use X::Nightscape;
unit class Nightscape::Config;

# class attributes {{{

# --- scene {{{

has Nightscape::Config::Ledger:D @.ledger is required;

my Costing:D $default-base-costing = FIFO;
has Costing:D $.base-costing = $default-base-costing;

my AssetCode:D $default-base-currency = 'USD';
has AssetCode:D $.base-currency = $default-base-currency;

my Str:D $now-year-end = sprintf(Q{%s-12-31}, now.Date.year);
my Date:D $default-fiscal-year-end = Date.new($now-year-end);
has Date:D $.fiscal-year-end = $default-fiscal-year-end;

has Nightscape::Config::Account:D @.account;
has Nightscape::Config::Asset:D @.asset;
has Nightscape::Config::Entity:D @.entity;

# --- end scene }}}
# --- setup {{{

# application settings
has AbsolutePath:D $.app-dir is required;
has AbsolutePath:D $.app-file is required;
has AbsolutePath:D $.log-dir is required;
has AbsolutePath:D $.pkg-dir is required;
has AbsolutePath:D $.price-dir is required;
my AbsolutePath:D $default-app-dir =
    sprintf(Q{%s/.config/nightscape}, $*HOME);
my AbsolutePath:D $default-log-dir =
    sprintf(Q{%s/log}, $default-app-dir);
my AbsolutePath:D $default-pkg-dir =
    sprintf(Q{%s/pkg}, $default-app-dir);
my AbsolutePath:D $default-price-dir =
    sprintf(Q{%s/prices}, $default-app-dir);
my AbsolutePath:D $default-app-file =
    sprintf(Q{%s/nightscape.toml}, $default-app-dir);

# scene settings
has AbsolutePath:D $.scene-dir is required;
has AbsolutePath:D $.scene-file is required;
my AbsolutePath:D $default-scene-dir =
    sprintf(Q{%s/.nightscape}, $*CWD);
my AbsolutePath:D $default-scene-file =
    sprintf(Q{%s/scene.toml}, $default-scene-dir);

# --- end setup }}}

# end class attributes }}}

# submethod BUILD {{{

submethod BUILD(
    Str :$app-dir,
    Str :$app-file,
    Str :$log-dir,
    Str :$pkg-dir,
    Str :$price-dir,
    Str :$scene-dir,
    Str :$scene-file,
    Nightscape::Config::Ledger:D :@ledger
    --> Nil
)
{
    # --- application settings {{{

    # if option C<app-file> is passed to instantiate
    # C<Nightscape::Config>, use that, otherwise use default
    my %app-file-content;
    $!app-file =
        resolve-path($default-app-file, $app-file);
    %app-file-content<app-dir> =
        resolve-path($default-app-dir, $app-dir);
    %app-file-content<log-dir> =
        resolve-path($default-log-dir, $log-dir);
    %app-file-content<pkg-dir> =
        resolve-path($default-pkg-dir, $pkg-dir);
    %app-file-content<price-dir> =
        resolve-path($default-price-dir, $price-dir);
    %app-file-content<scene-dir> =
        resolve-path($default-scene-dir, $scene-dir);
    %app-file-content<scene-file> =
        resolve-path($default-scene-file, $scene-file);

    # write values to C<$!app-file> if C<$!app-file> DNE
    my Str:D $app-file-content = to-toml(%app-file-content);
    prepare-config-file($!app-file, $app-file-content);

    # attempt to parse C<$!app-file>
    my %app = from-toml(:file($!app-file));

    # options C<app-dir>, C<log-dir>, C<pkg-dir>, C<price-dir>,
    # C<scene-dir>, passed to instantiate C<Nightscape::Config> override
    # settings of the same name contained in C<$!app-file>
    #
    # if no setting is provided, use defaults
    $!app-dir = resolve-path($default-app-dir, %app<app-dir>, $app-dir);
    $!log-dir = resolve-path($default-log-dir, %app<log-dir>, $log-dir);
    $!pkg-dir = resolve-path($default-pkg-dir, %app<pkg-dir>, $pkg-dir);
    $!price-dir = resolve-path($default-price-dir, %app<price-dir>, $price-dir);
    $!scene-dir = resolve-path($default-scene-dir, %app<scene-dir>, $scene-dir);
    prepare-config-dirs(
        $!app-dir,
        $!log-dir,
        $!pkg-dir,
        $!price-dir,
        $!scene-dir
    );

    # --- end application settings }}}
    # --- scene settings {{{

    # if option C<scene-file> is passed to instantiate
    # C<Nightscape::Config> override settings of the same name contained
    # in C<$!app-file>
    #
    # if no setting is provided, use default
    $!scene-file =
        resolve-path($default-scene-file, %app<scene-file>, $scene-file);
    my %scene-file-content;
    %scene-file-content<base-costing> = ~$default-base-costing;
    %scene-file-content<base-currency> = $default-base-currency;
    %scene-file-content<fiscal-year-end> = $default-fiscal-year-end;
    my Str:D $scene-file-content = to-toml(%scene-file-content);
    prepare-config-file($!scene-file, $scene-file-content);

    # attempt to parse C<$!scene-file>
    my %scene = from-toml(:file($!scene-file));

    try
    {
        CATCH { default { say(.message); exit(1) } };
        @!ledger =
            @ledger // gen-settings(:ledger(%scene<ledger>, :$!scene-file));
        @!account = gen-settings(:account(%scene<account>))
            if %scene<account>;
        @!asset = gen-settings(:asset(%scene<asset>), :$!scene-file)
            if %scene<asset>;
        @!entity = gen-settings(:entity(%scene<entity>), :$!scene-file)
            if %scene<entity>;
        $!base-currency = gen-asset-code(%scene<base-currency>)
            if %scene<base-currency>;
        $!base-costing = gen-costing(%scene<base-costing>)
            if %scene<base-costing>;
        $!fiscal-year-end = %scene<fiscal-year-end>
            if %scene<fiscal-year-end>;
    }

    # --- end scene settings }}}
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
        Nightscape::Config::Ledger:D :ledger(@)
    )
    --> Nightscape::Config:D
)
{
    self.bless(|%opts);
}

# end method new }}}
# sub gen-settings {{{

multi sub gen-settings(
    :@account!
    --> Array[Nightscape::Config::Account:D]
)
{
    my Nightscape::Config::Account:D @a =
        @account.hyper.map(-> %toml {
            Nightscape::Config::Account.new(|%toml)
        });
}

multi sub gen-settings(
    :@asset!,
    :$scene-file!
    --> Array[Nightscape::Config::Asset:D]
)
{
    my Nightscape::Config::Asset:D @a =
        @asset.hyper.map(-> %toml {
            Nightscape::Config::Asset.new(|%toml, :$scene-file)
        });
}

multi sub gen-settings(
    :@entity!,
    :$scene-file!
    --> Array[Nightscape::Config::Entity:D]
)
{
    my Nightscape::Config::Entity:D @a =
        @entity.hyper.map(-> %toml {
            Nightscape::Config::Entity.new(|%toml, :$scene-file)
        });
}

# ledger specified
multi sub gen-settings(
    :@ledger!,
    :$scene-file!
    --> Array[Nightscape::Config::Ledger:D]
)
{
    my Nightscape::Config::Ledger:D @a =
        @ledger.hyper.map(-> %toml {
            Nightscape::Config::Ledger.new(|%toml, :$scene-file)
        });
}

# ledger unspecified
multi sub gen-settings(
    :$ledger!
    --> Nil
)
{
    die(X::Nightscape::Config::Ledger::Missing.new);
}

# end sub gen-settings }}}
# sub prepare-config-dirs {{{

sub prepare-config-dirs(*@config-dir --> Nil)
{
    @config-dir.map(-> Str:D $config-dir {
        prepare-config-dir($config-dir)
    });
}

multi sub prepare-config-dir(Str:D $config-dir where .so --> Nil)
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
        or die(X::Nightscape::Config::Mkdir::Failed.new(:$text));
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
    die(X::Nightscape::Config::PrepareConfigDir::NotReadable.new);
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
    die(X::Nightscape::Config::PrepareConfigDir::NotWriteable.new);
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
    die(X::Nightscape::Config::PrepareConfigDir::NotADirectory.new);
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
    die(X::Nightscape::Config::PrepareConfigFile::NotReadable.new);
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
    die(X::Nightscape::Config::PrepareConfigFile::NotWriteable.new);
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
    die(X::Nightscape::Config::PrepareConfigFile::NotAFile.new);
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
