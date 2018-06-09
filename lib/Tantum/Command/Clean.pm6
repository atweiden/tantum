use v6;
use Tantum::Config;
use Tantum::Types;
unit class Command::Clean;

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
