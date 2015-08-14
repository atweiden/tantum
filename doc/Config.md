Nightscape Config
=================

Overview
--------

Nightscape uses [TOML](https://github.com/toml-lang/toml)
for config files.

The default config file is `$HOME/.config/nightscape/config.toml`.


Base Currency
-------------

The base currency / asset must be specified with the `base-currency`
key at the top level of the config file. All entities will inherit this
base currency by default unless a different base currency is specified
in their config section.

```toml
base-currency = "USD"

[AnEntityNamedFoo]
base-currency = "JPY"
```


Entities
--------

At least one entity must be declared in the config file. An individual
may want to use the word `Personal` or `FirstnameLastname`. A business
owner could declare his/her own business name. It is OK to list multiple
businesses along with a personal entity in the same config file.

```toml
[Personal]

[AcmeCo]

[Foo]
```

Entity names must adhere to Nightscape syntax guidelines. Alphanumeric
characters only. No whitespace, and no special characters besides dashes
(`-`) and underscores (`_`).

Optionally, each entity can include a `base-currency` directive. The
value of `base-currency` is a user-defined currency code or asset code,
contained within double-quotes.

```toml
[Personal]
base-currency = "USD"

[AcmeCo]
base-currency = "AUD"
```

Optionally, each entity can include an `open` directive. The value of
`open` is a perl-y ISO date range contained within double-quotes.

```toml
[AcmeCo]
open = "2014-01-01 .. *" # AcmeCo opens on Jan 1, 2014 and never closes

[AAA]
open = "1985-01-01 .. 2020-12-31" # AAA, from Jan 1, 1985 - Dec 31, 2020
```

Nightscape will check to ensure entities with listed `open` directives
in the config file make no transaction journal entries outside of the
given valid date range.


Subaccounts
-----------

Subaccount declarations are optional. Use subaccount sections to configure
an `open` status for bank accounts, brokerage accounts, and other Asset
accounts; as well as credit cards and other Liability accounts.

Each subaccount inherits its base currency from its parent entity.

Optionally, each subaccount can include an `open` directive.

```toml
[AcmeCo:Bankwest:Cheque]
open = "2014-01-01 .. *" # AcmeCo opens Bankwest Cheque account on Jan 1, 2014 and never closes it
```

Nightscape will check to ensure each subaccount with an `open` directive
in the config file makes no transaction journal entries outside of the
given valid date range.

In cases where both the entity and its subaccount provide an `open`
date range, Nightscape will check to ensure the subaccount’s given
`open` date range falls within the valid date range of its parent entity.

```toml
[AcmeCo]
open = "2014-01-01 .. *" # AcmeCo opens on Jan 1, 2014 and never closes

[AcmeCo.Bankwest.Cheque]
open = "2022-01-01 .. *" # valid, falls within 2014-01-01 and inf
```

```toml
[Personal]
open = "2014-01-01 .. *"

[Personal.Walmart.GiftCard]
open = "2012-01-01 .. 2013-03-04" # invalid, occurs before entity opened on 2014-01-01
```


Asset Price Data
----------------

`Assets` is a special config section for providing price data for assets,
foreign currencies or cryptocurrencies that appear in the transaction
journal.

Each `Assets` config section header must be written in the form `Assets`
`.` `asset_code_1` `.` `Prices` `.` `asset_code_2`. For example,
`Assets.BTC.Prices.USD` reads:

> The asset BTC, with prices in USD

```toml
[Assets.BTC.Prices.USD]
price-file = "/path/to/csv"
"2014-01-01" = 770.4357
"2014-01-02" = 808.0485
"2014-01-03" = 830.024
"2014-01-04" = 858.9833
"2014-01-05" = 940.0972
"2014-01-06" = 951.3865
"2014-01-07" = 810.5833
```

There are two possible options to set in each `Assets` group.

Setting    | Value
---        | ---
price-file | Path to file containing a list of date-price pairs in the format TBD (must be in double quotes)
ISO date (must be in double quotes) | Price on ISO 8601 date

ISO date (manual) price entries in each `Assets` config section override
price data from the listed price file if both are competing to provide
data for the same date.

Price data given in the transaction journal (with `@` syntax) will
override any conflicting price data listed in the config file.
