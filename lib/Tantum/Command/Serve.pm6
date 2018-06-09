use v6;
use Tantum::Config;
use Tantum::Types;
unit class Command::Serve;

# method serve {{{

method serve(*@ledger --> Nil)
{
    self!serve(|@ledger);
}

# end method serve }}}
# method !serve {{{

method !serve(*@ledger --> Nil)
{
    serve(|@ledger);
}

# end method !serve }}}
# sub serve {{{

multi sub serve(*@ledger where .so --> Nil)
{
    say('[DEBUG] serve:@ledger.so');
}

multi sub serve(*@ledger --> Nil)
{
    say('[DEBUG] serve');
}

# end sub serve }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
