use v6;
use Tantum::Config;
use Tantum::Types;
unit class Command::Show;

# method show {{{

method show(*@ledger --> Nil)
{
    self!show(|@ledger);
}

# end method show }}}
# method !show {{{

method !show(*@ledger --> Nil)
{
    show(|@ledger);
}

# end method !show }}}
# sub show {{{

multi sub show(*@ledger where .so --> Nil)
{
    say('[DEBUG] show:@ledger.so');
}

multi sub show(*@ledger --> Nil)
{
    say('[DEBUG] show');
}

# end sub show }}}

# vim: set filetype=raku foldmethod=marker foldlevel=0:
