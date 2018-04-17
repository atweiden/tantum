use v6;
unit module Nightscape::Types;

# AbsolutePath {{{

subset AbsolutePath of Str is export where .IO.is-absolute;

# end AbsolutePath }}}
# Costing {{{

enum Costing <AVCO FIFO LIFO>;

# end Costing }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
