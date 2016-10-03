use v6;
unit module X::Nightscape;

# X::Nightscape::Config::Ledger::Malformed {{{

class Config::Ledger::Malformed is Exception
{
    method message() returns Str:D
    {
        'Malformed ledger sources in scene config file';
    }
}

# end X::Nightscape::Config::Ledger::Malformed }}}
# X::Nightscape::Config::Ledger::Missing {{{

class Config::Ledger::Missing is Exception
{
    method message() returns Str:D
    {
        'Missing ledger sources in scene config file';
    }
}

# end X::Nightscape::Config::Ledger::Missing }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
