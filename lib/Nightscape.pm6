use v6;
use Nightscape::Command::Clean;
use Nightscape::Command::Reup;
use Nightscape::Command::Serve;
use Nightscape::Command::Show;
use Nightscape::Command::Sync;
use Nightscape::Config;
use Nightscape::Registry;
use Nightscape::Types;
use TXN::Parser::Types;
unit class Nightscape;

constant $PROGRAM = 'Nightscape';
constant $VERSION = v0.1.0;

has Nightscape::Config:D $.config is required;
has Nightscape::Registry:D $!registry = Nightscape::Registry.new;

# submethod BUILD {{{

submethod BUILD(
    *%setup-opts (
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
    --> Nil
)
{
    $!config = Nightscape::Config.new(|%setup-opts);
}

# end submethod BUILD }}}
# method new {{{

method new(
    *%setup-opts (
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
    --> Nightscape:D
)
{
    self.bless(|%setup-opts);
}

# end method new }}}


# -----------------------------------------------------------------------------
# commands
# -----------------------------------------------------------------------------

# method clean {{{

method clean(::?CLASS:D: *@ledger --> Nil)
{
    my Nightscape::Config:D $*config = $.config;
    Nightscape::Command::Clean.clean(|@ledger);
}

# end method clean }}}
# method reup {{{

method reup(
    ::?CLASS:D:
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($),
        Bool :no-sync($)
    ),
    *@ledger
    --> Nil
)
{
    my Nightscape::Config:D $*config = $.config;
    my Nightscape::Registry:D $*registry = $!registry;
    Nightscape::Command::Reup.reup(|%opts, |@ledger);
}

# end method reup }}}
# method serve {{{

method serve(::?CLASS:D: *@ledger --> Nil)
{
    my Nightscape::Config:D $*config = $.config;
    Nightscape::Command::Serve.serve(|@ledger);
}

# end method serve }}}
# method show {{{

method show(::?CLASS:D: *@ledger --> Nil)
{
    my Nightscape::Config:D $*config = $.config;
    Nightscape::Command::Show.show(|@ledger);
}

# end method show }}}
# method sync {{{

method sync(
    ::?CLASS:D:
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($)
    ),
    *@ledger
    --> List:D
)
{
    my Nightscape::Config:D $*config = $.config;
    my Nightscape::Registry:D $*registry = $!registry;
    Nightscape::Command::Sync.sync(|%opts, |@ledger);
}

# end method sync }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
