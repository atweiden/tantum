use v6;
unit module Nightscape::Types;

# AbsolutePath {{{

subset AbsolutePath of Str is export where .IO.is-absolute;

# end AbsolutePath }}}
# Costing {{{

enum Costing is export <AVCO FIFO LIFO>;

# end Costing }}}
# HookType {{{

enum HookType is export <POSTING ENTRY LEDGER COA HODL HOOK>;

# end HookType }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
