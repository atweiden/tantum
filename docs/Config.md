Nightscape Config
=================

Overview
--------

Nightscape uses [TOML](https://github.com/toml-lang/toml)
for config files.

The default config file is `$HOME/.config/nightscape/config.toml`.


The Default Group
-----------------

The `Default` group is the only mandatory section in the config
file. Under the `Default` group, you must specify `base-currency`. All
other accounts will inherit this base currency setting (and any other
settings in the `Default` group).

```toml
[Default]
base-currency = "USD"
```


Accounts
--------

Accounts can optionally be declared in the config file. The primary
benefit of doing so is to configure base currency and other account
options on a per-account basis.

It is not necessary to declare empty parent accounts when a subaccount
is declared. Subaccounts, like `Assets:Personal:Bankwest:Cheque` inherit
config options from parent accounts, and from the `Default` group:

```toml
[Default]
base-currency = "USD"

[Personal]
# this group not needed, since child account exists

[Personal.Bankwest.Cheque]
# inherits base-currency from first of Personal:Bankwest, Personal, or Default
# in this case, inherits USD from Default group
```

Accounts can be optionally opened and closed from the config using the key
`open` followed by an ISO 8601 date range (`YYYY-MM-DD .. YYYY-MM-DD`):

```toml
[Personal.Bankwest.Cheque]
open = "2014-01-01 .. *" # this account opens on Jan 1, 2014 and never closes

[Business]
open = "2014-01-01 .. 2015-03-05" # opens on Jan 1, 2014 and closes Mar 5, 2015
```

Opening/closing of accounts is optional.


Currencies
----------

The `Currencies` group is for providing price data for any assets, foreign
currencies or cryptocurrencies that appear in your transaction journal.

You must correctly name all `Currencies` in the form `Currencies`
`.` `COMMODITY_CODE` `.` `PRICES` `.` `COMMODITY_CODE`. For example,
`Currencies.BTC.Prices.USD` reads:

> The currency BTC, with prices in USD

```toml
[Currencies.BTC.Prices.USD]
price-file = "/path/to/csv"
"2014-01-01" = 770.4357
"2014-01-02" = 808.0485
"2014-01-03" = 830.024
"2014-01-04" = 858.9833
"2014-01-05" = 940.0972
"2014-01-06" = 951.3865
"2014-01-07" = 810.5833
```

There are two possible options to set in each `Currencies` group.

Setting    | Value
---        | ---
price-file | Path to file containing a list of date-price pairs in the format TBD (must be in double quotes)
ISO date (must be in double quotes) | Price on ISO 8601 date

Price data given in the transaction journal (with `@` syntax) will
override any conflicting price data listed in the config file.
