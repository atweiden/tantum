use v6;
unit module Nightscape::Types;

# AbsolutePath {{{

subset AbsolutePath of Str is export where *.IO.is-absolute;

# end AbsolutePath }}}
# Costing {{{

enum Costing is export <AVCO FIFO LIFO>;

# end Costing }}}
# Price {{{

subset Price of FatRat is export where * >= 0;

# end Price }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
