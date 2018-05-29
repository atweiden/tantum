use v6;
use Nightscape::Command::Sync;
use Nightscape::Config;
use Nightscape::Types;
unit class Command::Reup;

# method reup {{{

method reup(
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($),
        Bool :no-sync($)
    ),
    *@ledger
    --> Nil
)
{
    self!reup(|%opts, |@ledger);
}

# end method reup }}}
# method !reup {{{

method !reup(
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($),
        Bool :no-sync($)
    ),
    *@ledger
    --> Nil
)
{
    reup(|%opts, |@ledger);
}

# end method !reup }}}
# sub reup {{{

multi sub reup(
    Bool:D :no-sync($)! where .so,
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($)
    ),
    *@ledger
    --> Nil
)
{
    say('[DEBUG] reup:nosync');
}

multi sub reup(
    Bool :no-sync($),
    *%opts (
        Int :date-local-offset($),
        Str :include-lib($)
    ),
    *@ledger
    --> Nil
)
{
    Command::Sync.sync(|%opts, |@ledger);
}

# end sub reup }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
