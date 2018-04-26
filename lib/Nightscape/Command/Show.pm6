use v6;
use Nightscape::Config;
use Nightscape::Types;
unit class Nightscape::Command::Show;

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

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
