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
# X::Nightscape::Config::Asset::PriceFile::DNERF {{{

class Config::Asset::PriceFile::DNERF is Exception
{
    method message() returns Str:D
    {
        'Asset price file given in scene config file '
            ~ 'but does not exist in readable form';
    }
}

# end X::Nightscape::Config::Asset::PriceFile::DNERF }}}
# X::Nightscape::Config::Entity::Malformed {{{

class Config::Entity::Malformed is Exception
{
    method message() returns Str:D
    {
        'Malformed entity in scene config file';
    }
}

# end X::Nightscape::Config::Entity::Malformed }}}
# X::Nightscape::Config::Ledger::FromFile::DNERF {{{

class Config::Ledger::FromFile::DNERF is Exception
{
    method message() returns Str:D
    {
        'Ledger source from file given in scene config file '
            ~ 'but does not exist in readable form';
    }
}

# end X::Nightscape::Config::Ledger::FromFile::DNERF }}}
# X::Nightscape::Config::Ledger::FromPkg::DNERF {{{

class Config::Ledger::FromPkg::DNERF is Exception
{
    method message() returns Str:D
    {
        'Ledger source from pkg given in scene config file '
            ~ 'but does not exist in readable form';
    }
}

# end X::Nightscape::Config::Ledger::FromPkg::DNERF }}}
# X::Nightscape::Config::Ledger::FromPkg::TXNINFO::DNERF {{{

class Config::Ledger::FromPkg::TXNINFO::DNERF is Exception
{
    method message() returns Str:D
    {
        'Could not find .TXNINFO in ledger pkg';
    }
}

# end X::Nightscape::Config::Ledger::FromPkg::TXNINFO::DNERF }}}
# X::Nightscape::Config::Ledger::FromPkg::TXNJSON::DNERF {{{

class Config::Ledger::FromPkg::TXNJSON::DNERF is Exception
{
    method message() returns Str:D
    {
        'Could not find txn.json in ledger pkg';
    }
}

# end X::Nightscape::Config::Ledger::FromPkg::TXNJSON::DNERF }}}
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
# X::Nightscape::Config::Mkdir::Failed {{{

class Config::Mkdir::Failed is Exception
{
    has Str:D $.text is required;
    method message() returns Str:D
    {
        $.text;
    }
}

# end X::Nightscape::Config::Mkdir::Failed }}}
# X::Nightscape::Config::PrepareConfigDir::NotReadable {{{

class Config::PrepareConfigDir::NotReadable is Exception
{
    method message() returns Str:D
    {
        'Could not prepare config dir, existing not readable';
    }
}

# end X::Nightscape::Config::PrepareConfigDir::NotReadable }}}
# X::Nightscape::Config::PrepareConfigDir::NotWriteable {{{

class Config::PrepareConfigDir::NotWriteable is Exception
{
    method message() returns Str:D
    {
        'Could not prepare config dir, existing is not writeable';
    }
}

# end X::Nightscape::Config::PrepareConfigDir::NotWriteable }}}
# X::Nightscape::Config::PrepareConfigDir::NotADirectory {{{

class Config::PrepareConfigDir::NotADirectory is Exception
{
    method message() returns Str:D
    {
        'Could not prepare config dir, existing is not a directory';
    }
}

# end X::Nightscape::Config::PrepareConfigDir::NotADirectory }}}
# X::Nightscape::Config::PrepareConfigFile::NotReadable {{{

class Config::PrepareConfigFile::NotReadable is Exception
{
    method message() returns Str:D
    {
        'Could not prepare config file, existing not readable';
    }
}

# end X::Nightscape::Config::PrepareConfigFile::NotReadable }}}
# X::Nightscape::Config::PrepareConfigFile::NotWriteable {{{

class Config::PrepareConfigFile::NotWriteable is Exception
{
    method message() returns Str:D
    {
        'Could not prepare config file, existing is not writeable';
    }
}

# end X::Nightscape::Config::PrepareConfigFile::NotWriteable }}}
# X::Nightscape::Config::PrepareConfigFile::NotADirectory {{{

class Config::PrepareConfigFile::NotADirectory is Exception
{
    method message() returns Str:D
    {
        'Could not prepare config file, existing is not a file';
    }
}

# end X::Nightscape::Config::PrepareConfigFile::NotADirectory }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
