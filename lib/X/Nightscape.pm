use v6;
unit module X::Nightscape;

# X::Nightscape::Config::Account::Malformed {{{

class Config::Account::Malformed is Exception
{
    method message() returns Str:D
    {
        'Malformed account in scene config file';
    }
}

# end X::Nightscape::Config::Account::Malformed }}}
# X::Nightscape::Config::Asset::Malformed {{{

class Config::Asset::Malformed is Exception
{
    method message() returns Str:D
    {
        'Malformed asset in scene config file';
    }
}

# end X::Nightscape::Config::Asset::Malformed }}}
# X::Nightscape::Config::Asset::Price::Malformed {{{

class Config::Asset::Price::Malformed is Exception
{
    method message() returns Str:D
    {
        'Malformed asset pricing in scene config file';
    }
}

# end X::Nightscape::Config::Asset::Price::Malformed }}}
# X::Nightscape::Config::Entity::Malformed {{{

class Config::Entity::Malformed is Exception
{
    method message() returns Str:D
    {
        'Malformed entity in scene config file';
    }
}

# end X::Nightscape::Config::Entity::Malformed }}}
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
