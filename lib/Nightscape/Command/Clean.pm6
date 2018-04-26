use v6;
use Nightscape::Config;
use Nightscape::Types;
unit class Nightscape::Command::Clean;

# method clean {{{

method clean(*@ledger --> Nil)
{
    self!clean(|@ledger);
}

# end method clean }}}
# method !clean {{{

method !clean(*@ledger --> Nil)
{
    clean(|@ledger);
}

# end method !clean }}}
# sub clean {{{

multi sub clean(*@ledger where .so --> Nil)
{
    say('[DEBUG] clean:@ledger.so');
}

multi sub clean(*@ledger --> Nil)
{
    say('[DEBUG] clean');
}

# end sub clean }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
