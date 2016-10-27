use v6;
use Config::TOML;
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

my Date:D $default-fiscal-year-end = Date.new(now.Date.year ~ '-12-31');
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
my AbsolutePath:D $default-app-dir = "$*HOME/.config/nightscape";
my AbsolutePath:D $default-log-dir = "$default-app-dir/logs";
my AbsolutePath:D $default-pkg-dir = "$default-app-dir/pkgs";
my AbsolutePath:D $default-price-dir = "$default-app-dir/prices";
my AbsolutePath:D $default-app-file = "$default-app-dir/nightscape.toml";
my Str:D $default-app-file-contents = to-toml(%(
    :app-dir($default-app-dir),
    :log-dir($default-log-dir),
    :pkg-dir($default-pkg-dir),
    :price-dir($default-price-dir)
));

# scene settings
has AbsolutePath:D $.scene-dir is required;
has AbsolutePath:D $.scene-file is required;
my AbsolutePath:D $default-scene-dir = "$*CWD/.nightscape";
my AbsolutePath:D $default-scene-file = "$default-scene-dir/scene.toml";
my Str:D $default-scene-file-contents = to-toml(%(
    :base-costing("$default-base-costing"),
    :base-currency($default-base-currency),
    :fiscal-year-end($default-fiscal-year-end)
));

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
    Str :$scene-file
)
{
    # --- application settings {{{

    # if option C<app-file> is passed to instantiate
    # C<Nightscape::Config>, use that, otherwise use default
    $!app-file = $app-file ?? resolve-path($app-file) !! $default-app-file;
    prepare-config-file($!app-file, $default-app-file-contents);

    # attempt to parse C<$!app-file>
    my %app = from-toml(:file($!app-file));

    # options C<app-dir>, C<log-dir>, C<pkg-dir>, C<price-dir>, passed
    # to instantiate C<Nightscape::Config> override settings of the same
    # name contained in C<$!app-file>
    #
    # if no setting is provided, use defaults
    $!app-dir = resolve-dir($default-app-dir, %app<app-dir>, $app-dir);
    $!log-dir = resolve-dir($default-log-dir, %app<log-dir>, $log-dir);
    $!pkg-dir = resolve-dir($default-pkg-dir, %app<pkg-dir>, $pkg-dir);
    $!price-dir = resolve-dir($default-price-dir, %app<price-dir>, $price-dir);
    prepare-config-dirs($!app-dir, $!log-dir, $!pkg-dir, $!price-dir);

    # --- end application settings }}}
    # --- scene settings {{{

    # if option C<scene-file> is passed to instantiate
    # C<Nightscape::Config>, use that, otherwise use default
    $!scene-file = $scene-file ?? resolve-path($scene-file) !! $default-scene-file;
    prepare-config-file($!scene-file, $default-scene-file-contents);

    # attempt to parse C<$!scene-file>
    my %scene = from-toml(:file($!scene-file));

    # option C<scene-dir> passed to instantiate C<Nightscape::Config>
    # overrides setting of the same name contained in C<$!scene-file>
    #
    # if no setting is provided, use defaults
    $!scene-dir = resolve-dir($default-scene-dir, %scene<scene-dir>, $scene-dir);
    prepare-config-dirs($!scene-dir);

    try
    {
        CATCH { default { .message.say; exit 1 } };
        @!ledger = gen-settings(:ledger(%scene<ledger>));
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
        Str :scene-file($)
    )
)
{
    self.bless(|%opts);
}

# end method new }}}
# sub gen-settings {{{

multi sub gen-settings(:@account!) returns Array:D
{
    my Nightscape::Config::Account:D @a =
        @account.map({ Nightscape::Config::Account.new(|$_) });
}

multi sub gen-settings(:@asset!, :$scene-file!) returns Array:D
{
    my Nightscape::Config::Asset:D @a =
        @asset.map({ Nightscape::Config::Asset.new(|$_, :$scene-file) });
}

multi sub gen-settings(:@entity!, :$scene-file!) returns Array:D
{
    my Nightscape::Config::Entity:D @a =
        @entity.map({ Nightscape::Config::Entity.new(|$_, :$scene-file) });
}

# ledger specified
multi sub gen-settings(:@ledger!) returns Array[Nightscape::Config::Ledger:D]
{
    my Nightscape::Config::Ledger:D @a =
        @ledger.map({ Nightscape::Config::Ledger.new(|$_) });
}

# ledger unspecified
multi sub gen-settings(:$ledger!)
{
    die X::Nightscape::Config::Ledger::Missing.new;
}

# end sub gen-settings }}}
# sub prepare-config-dirs {{{

sub prepare-config-dirs(*@dirs)
{
    prepare-config-dir($_) for @dirs;
}

sub prepare-config-dir(Str:D $dir where *.so)
{
    given File::Presence.show($dir)
    {
        when !$_<e>
        {
            $dir.IO.mkdir or die X::Nightscape::Config::Mkdir::Failed.new(
                :text('Could not prepare config dir, failed to create dir')
            );
        }
        when !$_<r>
        {
            die X::Nightscape::Config::PrepareConfigDir::NotReadable.new;
        }
        when !$_<w>
        {
            die X::Nightscape::Config::PrepareConfigDir::NotWriteable.new;
        }
        when !$_<d>
        {
            die X::Nightscape::Config::PrepareConfigDir::NotADirectory.new;
        }
        default
        {
            True;
        }
    }
}

# end sub prepare-config-dirs }}}
# sub prepare-config-file {{{

sub prepare-config-file(
    Str:D $config-file where *.so,
    Str:D $config-file-contents where *.so
)
{
    given File::Presence.show($config-file)
    {
        # create config file if DNE
        when !$_<e>
        {
            my Str:D $config-file-basedir = $config-file.IO.dirname;
            $config-file-basedir.IO.mkdir unless $config-file-basedir.IO.d;
            $config-file.IO.spurt("$config-file-contents\n", :createonly);
        }
        when !$_<r>
        {
            die X::Nightscape::Config::PrepareConfigFile::NotReadable.new;
        }
        when !$_<w>
        {
            die X::Nightscape::Config::PrepareConfigFile::NotWriteable.new;
        }
        when !$_<f>
        {
            die X::Nightscape::Config::PrepareConfigFile::NotAFile.new;
        }
        default
        {
            True;
        }
    }
}

# end sub prepare-config-file }}}
# sub resolve-dir {{{

sub resolve-dir($default-dir, $toml-dir?, $user-override-dir?) returns Str:D
{
    my Str:D $dir = do
        if $user-override-dir { $user-override-dir }
        elsif $toml-dir { $toml-dir }
        else { $default-dir };
    resolve-path($dir);
}

# end sub resolve-dir }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
