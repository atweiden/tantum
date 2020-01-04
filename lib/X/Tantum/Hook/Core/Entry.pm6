use v6;
use TXN::Parser::ParseTree;

my role Common
{...}

# X::Tantum::Hook::Core::Entry::NotBalanced {{{

class X::Tantum::Hook::Core::Entry::NotBalanced
{
    also is Exception;
    also does Common;

    method message(::?CLASS:D: --> Str:D)
    {
        my Str:D $message = 'Sorry, entry not balanced';
    }
}

# end X::Tantum::Hook::Core::Entry::NotBalanced }}}

my role Common
{
    has Entry:D $.entry is required;
}

# vim: set filetype=raku foldmethod=marker foldlevel=0:
