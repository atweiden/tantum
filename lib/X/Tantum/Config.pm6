use v6;

# X::Tantum::Config::Account::Malformed {{{

class X::Tantum::Config::Account::Malformed is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Malformed account in scene config file';
    }
}

# end X::Tantum::Config::Account::Malformed }}}
# X::Tantum::Config::Asset::Malformed {{{

class X::Tantum::Config::Asset::Malformed is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Malformed asset in scene config file';
    }
}

# end X::Tantum::Config::Asset::Malformed }}}
# X::Tantum::Config::Asset::Price::Malformed {{{

class X::Tantum::Config::Asset::Price::Malformed is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Malformed asset pricing in scene config file';
    }
}

# end X::Tantum::Config::Asset::Price::Malformed }}}
# X::Tantum::Config::Asset::PriceFile::DNERF {{{

class X::Tantum::Config::Asset::PriceFile::DNERF is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Asset price file given in scene config file '
                ~ 'but does not exist in readable form';
    }
}

# end X::Tantum::Config::Asset::PriceFile::DNERF }}}
# X::Tantum::Config::Entity::Malformed {{{

class X::Tantum::Config::Entity::Malformed is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Malformed entity in scene config file';
    }
}

# end X::Tantum::Config::Entity::Malformed }}}
# X::Tantum::Config::Ledger::FromFile::DNERF {{{

class X::Tantum::Config::Ledger::FromFile::DNERF is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Ledger source from file given in scene config file '
                ~ 'but does not exist in readable form';
    }
}

# end X::Tantum::Config::Ledger::FromFile::DNERF }}}
# X::Tantum::Config::Ledger::FromPkg::DNERF {{{

class X::Tantum::Config::Ledger::FromPkg::DNERF is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Ledger source from pkg given in scene config file '
                ~ 'but does not exist in readable form';
    }
}

# end X::Tantum::Config::Ledger::FromPkg::DNERF }}}
# X::Tantum::Config::Ledger::FromPkg::TXNINFO::DNERF {{{

class X::Tantum::Config::Ledger::FromPkg::TXNINFO::DNERF is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not find .TXNINFO in ledger pkg';
    }
}

# end X::Tantum::Config::Ledger::FromPkg::TXNINFO::DNERF }}}
# X::Tantum::Config::Ledger::FromPkg::TXNJSON::DNERF {{{

class X::Tantum::Config::Ledger::FromPkg::TXNJSON::DNERF is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not find txn.json in ledger pkg';
    }
}

# end X::Tantum::Config::Ledger::FromPkg::TXNJSON::DNERF }}}
# X::Tantum::Config::Ledger::Malformed {{{

class X::Tantum::Config::Ledger::Malformed is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Malformed ledger sources in scene config file';
    }
}

# end X::Tantum::Config::Ledger::Malformed }}}
# X::Tantum::Config::Ledger::Missing {{{

class X::Tantum::Config::Ledger::Missing is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Missing ledger sources in scene config file';
    }
}

# end X::Tantum::Config::Ledger::Missing }}}
# X::Tantum::Config::Mkdir::Failed {{{

class X::Tantum::Config::Mkdir::Failed is Exception
{
    has Str:D $.text is required;
    method message(::?CLASS:D: --> Str:D)
    {
        my Str:D $message = $.text;
    }
}

# end X::Tantum::Config::Mkdir::Failed }}}
# X::Tantum::Config::PrepareConfigDir::NotReadable {{{

class X::Tantum::Config::PrepareConfigDir::NotReadable is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not prepare config dir, existing not readable';
    }
}

# end X::Tantum::Config::PrepareConfigDir::NotReadable }}}
# X::Tantum::Config::PrepareConfigDir::NotWriteable {{{

class X::Tantum::Config::PrepareConfigDir::NotWriteable is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not prepare config dir, existing is not writeable';
    }
}

# end X::Tantum::Config::PrepareConfigDir::NotWriteable }}}
# X::Tantum::Config::PrepareConfigDir::NotADirectory {{{

class X::Tantum::Config::PrepareConfigDir::NotADirectory is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not prepare config dir, existing is not a directory';
    }
}

# end X::Tantum::Config::PrepareConfigDir::NotADirectory }}}
# X::Tantum::Config::PrepareConfigFile::NotReadable {{{

class X::Tantum::Config::PrepareConfigFile::NotReadable is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not prepare config file, existing not readable';
    }
}

# end X::Tantum::Config::PrepareConfigFile::NotReadable }}}
# X::Tantum::Config::PrepareConfigFile::NotWriteable {{{

class X::Tantum::Config::PrepareConfigFile::NotWriteable is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not prepare config file, existing is not writeable';
    }
}

# end X::Tantum::Config::PrepareConfigFile::NotWriteable }}}
# X::Tantum::Config::PrepareConfigFile::NotADirectory {{{

class X::Tantum::Config::PrepareConfigFile::NotADirectory is Exception
{
    method message(--> Str:D)
    {
        my Str:D $message =
            'Could not prepare config file, existing is not a file';
    }
}

# end X::Tantum::Config::PrepareConfigFile::NotADirectory }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
