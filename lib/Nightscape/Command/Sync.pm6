use v6;
use Nightscape::Config;
use Nightscape::Types;
unit class Nightscape::Command::Sync;

# method sync {{{

method sync(
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($)
    ),
    *@ledger
    --> Nil
)
{
    self!sync(|%opts, |@ledger);
}

# end method sync }}}
# method !sync {{{

method !sync(
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($)
    ),
    *@ledger
    --> Nil
)
{
    my AbsolutePath:D $pkg-dir = $*config.pkg-dir;
    sync($*config.ledger, :$pkg-dir, |%opts, |@ledger);
}

# end method !sync }}}
# sub sync {{{

multi sub sync(
    Nightscape::Config::Ledger:D @l,
    *%opts (
        AbsolutePath:D :pkg-dir($)!,
        Int :date-local-offset($),
        Str :include-lib($)
    ),
    *@request where .so
    --> Nil
)
{
    my Nightscape::Config::Ledger:D @ledger =
        grep-ledger-for-request(@l, @request);
    my List:D $pkg = sync(:@ledger, |%opts).List;
    sync(:$pkg);
}

multi sub sync(
    Nightscape::Config::Ledger:D @ledger,
    *%opts (
        AbsolutePath:D :pkg-dir($)!,
        Int :date-local-offset($),
        Str :include-lib($)
    ),
    *@
    --> Nil
)
{
    my List:D $pkg = sync(:@ledger, |%opts).List;
    sync(:$pkg);
}

multi sub sync(
    Nightscape::Config::Ledger:D :@ledger!,
    *%opts (
        AbsolutePath:D :pkg-dir($)! where .so,
        Int :date-local-offset($),
        Str :include-lib($)
    )
    --> List:D
)
{
    my List:D $sync =
        @ledger.hyper.map(-> Nightscape::Config::Ledger:D $ledger {
            sync(:$ledger, |%opts)
        }).List;
}

multi sub sync(
    Nightscape::Config::Ledger::FromFile:D :$ledger!,
    AbsolutePath:D :pkg-dir($)! where .so,
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
    Nightscape::Config::Ledger::FromPkg:D :$ledger!,
    AbsolutePath:D :$pkg-dir! where .so,
    *% (
        Int :date-local-offset($),
        Str :include-lib($)
    )
    --> Hash:D
)
{
    my %sync = $ledger.made(:$pkg-dir);
}

multi sub sync(
    List:D :$pkg!
    --> Nil
)
{
    .perl.say for $pkg.map({ $_<txn-info> });
}

# end sub sync }}}


# -----------------------------------------------------------------------------
# helper functions
# -----------------------------------------------------------------------------

# sub grep-ledger-for-request {{{

sub grep-ledger-for-request(
    Nightscape::Config::Ledger:D @ledger,
    Str:D @request
    --> Array[Nightscape::Config::Ledger:D]
)
{
    my Nightscape::Config::Ledger:D @grep-ledger-for-request =
        @ledger.hyper.grep(-> Nightscape::Config::Ledger:D $ledger {
            is-ledger-for-request($ledger, @request)
        });
}

multi sub is-ledger-for-request(
    Nightscape::Config::Ledger::FromFile:D $ledger,
    Str:D @request
    --> Bool:D
)
{
    my Bool:D $is-ledger-for-request = @request.grep($ledger.code).so;
}

multi sub is-ledger-for-request(
    Nightscape::Config::Ledger::FromPkg:D $ledger,
    Str:D @request
    --> Bool:D
)
{
    my Bool:D $is-ledger-for-request = @request.grep($ledger.pkgname).so;
}

# end sub grep-ledger-for-request }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
