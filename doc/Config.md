Nightscape Config
=================

Overview
--------

Nightscape uses [TOML](https://github.com/toml-lang/toml)
for config files.

The default config file is `$HOME/.nightscape/config.toml`.


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

Entity names must adhere to TOML syntax guidelines. Bare names follow
TOML bare key rules, in that unquoted names can only use alphanumeric
characters, dashes (`-`) and underscores (`_`). No whitespace and no
special characters are allowed in bare names.

Quoted names can contain special characters and spaces.

```toml
["12Fish Advertising"]
```

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
[AcmeCo.Bankwest.Cheque]
# AcmeCo opens Bankwest Cheque account on Jan 1, 2014 and never closes it
open = "2014-01-01 .. *"
```

Nightscape will check to ensure each subaccount with an `open` directive
in the config file makes no transaction journal entries outside of the
given valid date range.

In cases where both the entity and its subaccount provide an `open`
date range, Nightscape will check to ensure the subaccount’s given
`open` date range falls within the valid date range of its parent entity.

```toml
[AcmeCo]
# AcmeCo opens on Jan 1, 2014 and never closes
open = "2014-01-01 .. *"

[AcmeCo.Bankwest.Cheque]
# valid, falls within 2014-01-01 and inf
open = "2022-01-01 .. *"
```

```toml
[Personal]
open = "2014-01-01 .. *"

[Personal.Walmart.GiftCard]
# invalid, occurs before entity opened on 2014-01-01
open = "2012-01-01 .. 2013-03-04"
```


Asset Price Data
----------------

`Assets` is a special config section for providing price data for assets,
foreign currencies or cryptocurrencies that appear in the transaction
journal.

Each `Assets` config section header must be written in the form `Assets`
`.` `asset-code-1` `.` `Prices` `.` `asset-code-2`. For example,
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
2014-01-08T00:00:00Z = 859.9485 # RFC3339 timestamps are ok
```

There are three possible options to set in each `Assets` group.

Setting    | Value
---        | ---
price-file | Path to file containing list of date-price pairs in the format TBD (must be in double quotes)
date       | Price on date

Dates must be valid standard calendar dates (YYYY-MM-DD), RFC 3339
timestamps or RFC 3339 timestamps with local offset omitted.

Manual date-price entries in each `Assets` config section override price
data from the listed price file if both are competing to provide data
for the same date.

Price data given in the transaction journal (with `@` syntax) will
override any conflicting price data listed in the config file.
