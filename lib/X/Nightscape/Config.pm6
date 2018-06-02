use v6;

# X::Nightscape::Config::Account::Malformed {{{

class X::Nightscape::Config::Account::Malformed is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Malformed account in scene config file';
    }
}

# end X::Nightscape::Config::Account::Malformed }}}
# X::Nightscape::Config::Asset::Malformed {{{

class X::Nightscape::Config::Asset::Malformed is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Malformed asset in scene config file';
    }
}

# end X::Nightscape::Config::Asset::Malformed }}}
# X::Nightscape::Config::Asset::Price::Malformed {{{

class X::Nightscape::Config::Asset::Price::Malformed is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Malformed asset pricing in scene config file';
    }
}

# end X::Nightscape::Config::Asset::Price::Malformed }}}
# X::Nightscape::Config::Asset::PriceFile::DNERF {{{

class X::Nightscape::Config::Asset::PriceFile::DNERF is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Asset price file given in scene config file '
                ~ 'but does not exist in readable form';
    }
}

# end X::Nightscape::Config::Asset::PriceFile::DNERF }}}
# X::Nightscape::Config::Entity::Malformed {{{

class X::Nightscape::Config::Entity::Malformed is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Malformed entity in scene config file';
    }
}

# end X::Nightscape::Config::Entity::Malformed }}}
# X::Nightscape::Config::Ledger::FromFile::DNERF {{{

class X::Nightscape::Config::Ledger::FromFile::DNERF is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Ledger source from file given in scene config file '
                ~ 'but does not exist in readable form';
    }
}

# end X::Nightscape::Config::Ledger::FromFile::DNERF }}}
# X::Nightscape::Config::Ledger::FromPkg::DNERF {{{

class X::Nightscape::Config::Ledger::FromPkg::DNERF is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Ledger source from pkg given in scene config file '
                ~ 'but does not exist in readable form';
    }
}

# end X::Nightscape::Config::Ledger::FromPkg::DNERF }}}
# X::Nightscape::Config::Ledger::FromPkg::TXNINFO::DNERF {{{

class X::Nightscape::Config::Ledger::FromPkg::TXNINFO::DNERF is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not find .TXNINFO in ledger pkg';
    }
}

# end X::Nightscape::Config::Ledger::FromPkg::TXNINFO::DNERF }}}
# X::Nightscape::Config::Ledger::FromPkg::TXNJSON::DNERF {{{

class X::Nightscape::Config::Ledger::FromPkg::TXNJSON::DNERF is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not find txn.json in ledger pkg';
    }
}

# end X::Nightscape::Config::Ledger::FromPkg::TXNJSON::DNERF }}}
# X::Nightscape::Config::Ledger::Malformed {{{

class X::Nightscape::Config::Ledger::Malformed is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Malformed ledger sources in scene config file';
    }
}

# end X::Nightscape::Config::Ledger::Malformed }}}
# X::Nightscape::Config::Ledger::Missing {{{

class X::Nightscape::Config::Ledger::Missing is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Missing ledger sources in scene config file';
    }
}

# end X::Nightscape::Config::Ledger::Missing }}}
# X::Nightscape::Config::Mkdir::Failed {{{

class X::Nightscape::Config::Mkdir::Failed is Exception
{
    has Str:D $.text is required;
    method message(::?CLASS:D: --> Str:D)
    {
        my Str:D $message = $.text;
    }
}

# end X::Nightscape::Config::Mkdir::Failed }}}
# X::Nightscape::Config::PrepareConfigDir::NotReadable {{{

class X::Nightscape::Config::PrepareConfigDir::NotReadable is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not prepare config dir, existing not readable';
    }
}

# end X::Nightscape::Config::PrepareConfigDir::NotReadable }}}
# X::Nightscape::Config::PrepareConfigDir::NotWriteable {{{

class X::Nightscape::Config::PrepareConfigDir::NotWriteable is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not prepare config dir, existing is not writeable';
    }
}

# end X::Nightscape::Config::PrepareConfigDir::NotWriteable }}}
# X::Nightscape::Config::PrepareConfigDir::NotADirectory {{{

class X::Nightscape::Config::PrepareConfigDir::NotADirectory is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not prepare config dir, existing is not a directory';
    }
}

# end X::Nightscape::Config::PrepareConfigDir::NotADirectory }}}
# X::Nightscape::Config::PrepareConfigFile::NotReadable {{{

class X::Nightscape::Config::PrepareConfigFile::NotReadable is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not prepare config file, existing not readable';
    }
}

# end X::Nightscape::Config::PrepareConfigFile::NotReadable }}}
# X::Nightscape::Config::PrepareConfigFile::NotWriteable {{{

class X::Nightscape::Config::PrepareConfigFile::NotWriteable is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not prepare config file, existing is not writeable';
    }
}

# end X::Nightscape::Config::PrepareConfigFile::NotWriteable }}}
# X::Nightscape::Config::PrepareConfigFile::NotADirectory {{{

class X::Nightscape::Config::PrepareConfigFile::NotADirectory is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not prepare config file, existing is not a file';
    }
}

# end X::Nightscape::Config::PrepareConfigFile::NotADirectory }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
