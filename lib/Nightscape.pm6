use v6;
use Nightscape::Config;
use TXN::Parser;
use TXN::Parser::Types;
unit class Nightscape;

constant $PROGRAM = 'Nightscape';
constant $VERSION = v0.1.0;

has Nightscape::Config:D $.config is required;

# submethod BUILD {{{

submethod BUILD(
    *%setup-opts (
        Str :app-dir($),
        Str :app-file($),
        Str :log-dir($),
        Str :pkg-dir($),
        Str :price-dir($),
        Str :scene-dir($),
        Str :scene-file($)
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
        Str :scene-file($)
    )
    --> Nightscape:D
)
{
    self.bless(|%setup-opts);
}

# end method new }}}
# method clean {{{

method clean(::?CLASS:D: --> Nil)
{
    self!clean();
}

# end method clean }}}
# method reup {{{

method reup(
    ::?CLASS:D:
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($),
        :ledger(@),
        Bool :no-sync($)
    )
    --> Nil
)
{
    self!reup(|%opts);
}

# end method reup }}}
# method serve {{{

method serve(::?CLASS:D: --> Nil)
{
    self!serve();
}

# end method serve }}}
# method show {{{

method show(::?CLASS:D: --> Nil)
{
    self!show();
}

# end method show }}}
# method sync {{{

method sync(
    ::?CLASS:D:
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($)
    )
    --> Nil
)
{
    self!sync(|%opts);
}

# end method sync }}}
# method !clean {{{

method !clean(--> Nil)
{*}

# end method !clean }}}
# method !reup {{{

method !reup(--> Nil)
{*}

# end method !reup }}}
# method !serve {{{

method !serve(--> Nil)
{*}

# end method !serve }}}
# method !show {{{

method !show(--> Nil)
{*}

# end method !show }}}
# method !sync {{{

method !sync(
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($)
    )
    --> Nil
)
{
    my List:D $pkg = sync($.config.ledger, :pkg-dir($.config.pkg-dir), |%opts);
    .perl.say for $pkg.map({ $_<txn-info> });
}

# end method !sync }}}
# sub sync {{{

multi sub sync(
    Nightscape::Config::Ledger:D @ledger,
    *%opts (
        Str:D :pkg-dir($)! where .so,
        Int :date-local-offset($),
        Str :include-lib($)
    )
    --> List:D
)
{
    my List:D $sync = @ledger.map({ sync($_, |%opts) });
}

multi sub sync(
    Nightscape::Config::Ledger::FromFile:D $ledger,
    Str:D :pkg-dir($)! where .so,
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($)
    )
    --> Hash:D
)
{
    my %sync = $ledger.made(|%opts);
}

multi sub sync(
    Nightscape::Config::Ledger::FromPkg:D $ledger,
    Str:D :$pkg-dir! where .so,
    *% (
        Int :date-local-offset($),
        Str :include-lib($)
    )
    --> Hash:D
)
{
    my %sync = $ledger.made(:$pkg-dir);
}

# end sub sync }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
