use v6;
use TXN::Parser::ParseTree;

my role Common
{...}

# X::Tantum::Hook::Core::Entry::Posting::AccountClosed {{{

class X::Tantum::Hook::Core::Entry::Posting::AccountClosed
{
    also is Exception;
    also does Common;

    method message(::?CLASS:D: --> Str:D)
    {
        my Str:D $message = 'Sorry, account is closed';
    }
}

# end X::Tantum::Hook::Core::Entry::Posting::AccountClosed }}}
# X::Tantum::Hook::Core::Entry::Posting::EntityClosed {{{

class X::Tantum::Hook::Core::Entry::Posting::EntityClosed
{
    also is Exception;
    also does Common;

    method message(::?CLASS:D: --> Str:D)
    {
        my Str:D $message = 'Sorry, entity is closed';
    }
}

# end X::Tantum::Hook::Core::Entry::Posting::EntityClosed }}}
# X::Tantum::Hook::Core::Entry::Posting::XEMissing {{{

class X::Tantum::Hook::Core::Entry::Posting::XEMissing
{
    also is Exception;
    also does Common;

    method message(::?CLASS:D: --> Str:D)
    {
        my Str:D $message = 'Sorry, exchange rate is missing';
    }
}

# end X::Tantum::Hook::Core::Entry::Posting::XEMissing }}}

my role Common
{
    has Entry::Posting:D $.posting is required;
}

# vim: set filetype=raku foldmethod=marker foldlevel=0:
