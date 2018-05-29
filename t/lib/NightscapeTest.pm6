use v6;
use Nightscape::Config::Ledger;
use Nightscape::Types;
use TXN::Parser::Types;
unit class NightscapeTest;

method setup(--> Hash:D)
{
    my %setup = setup();
}

multi sub setup(--> Hash:D)
{
    my AbsolutePath:D $root = sprintf(Q{%s/t/data/root}, $*CWD);
    my AbsolutePath:D $app-dir = sprintf(Q{%s/.config/nightscape}, $root);
    my AbsolutePath:D $log-dir = sprintf(Q{%s/log}, $app-dir);
    my AbsolutePath:D $pkg-dir = sprintf(Q{%s/pkg}, $app-dir);
    my AbsolutePath:D $price-dir = sprintf(Q{%s/prices}, $app-dir);
    my AbsolutePath:D $app-file = sprintf(Q{%s/nightscape.toml}, $app-dir);
    my AbsolutePath:D $scene-dir = sprintf(Q{%s/.nightscape}, $root);
    my AbsolutePath:D $scene-file = sprintf(Q{%s/scene.toml}, $scene-dir);
    my Config::Ledger:D @ledger = setup('ledger', $scene-file);
    my %setup =
        :$app-dir,
        :$log-dir,
        :$pkg-dir,
        :$price-dir,
        :$app-file,
        :$scene-dir,
        :$scene-file,
        :@ledger;
}

multi sub setup(
    'ledger',
    AbsolutePath:D $scene-file
    --> Array[Config::Ledger:D]
)
{
    my VarNameBare:D $code = 'sample';
    my AbsolutePath:D $file = sprintf(Q{%s/t/data/sample/sample.txn}, $*CWD);
    my Config::Ledger:D @ledger =
        Config::Ledger.new(:$code, :$file, :$scene-file);
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
