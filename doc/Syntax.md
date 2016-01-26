Nightscape Syntax
=================

Entries
-------

- Journal entries must be separated by newline(s)

#### Unacceptable (missing newline separator between entries)

```
2014-01-01 I started the year with $1000 in Bankwest cheque account
  Assets:Personal:Bankwest:Cheque    $1000.00 USD
  Equity:Personal                    $1000.00 USD 2014-01-02 I paid Exxon Mobile $10 for gas from Bankwest cheque account
  Expenses:Personal:Fuel             $10.00 USD
  Assets:Personal:Bankwest:Cheque   -$10.00 USD
```

#### Acceptable

```
2014-01-01 I started the year with $1000 in Bankwest cheque account
  Assets:Personal:Bankwest:Cheque    $1000.00 USD
  Equity:Personal                    $1000.00 USD

2014-01-02 I paid Exxon Mobile $10 for gas from Bankwest cheque account
  Expenses:Personal:Fuel             $10.00 USD
  Assets:Personal:Bankwest:Cheque   -$10.00 USD
```


Dates
-----

Dates can come in three different forms:

1. [RFC 3339](http://tools.ietf.org/html/rfc3339) timestamps
   (`YYYY-MM-ddThh:mm:ss.ffff+zz`)
2. RFC 3339 timestamps with the local offset omitted
   (`YYYY-MM-ddThh:mm:ss.ffff`)
3. Standard calendar dates (`YYYY-MM-dd`)

#### Unacceptable (invalid full-year)

```
1-1-2015
1/1/2015
2015/01/01
Jan 1st, 2015
```

#### Unacceptable (invalid date-time)

Missing `[Tt]`:

```
2015-01-01 00:00:00Z
```

#### Acceptable

```
# YYYY-MM-DD
2015-01-01

# RFC3339 timestamp
2015-01-01T00:00:00Z
2015-01-01t00:00:00z
2015-01-01T00:00:00-07:00

# RFC3339 timestamp with local offset omitted
2015-01-01T07:32:00
2015-01-01T00:32:00.999999
```


Metainfo
--------

- Metainfo is optional
- Metainfo, when given, can come after the date separated by at least
  one whitespace or newline and/or after the description separated by
  at least one whitespace or newline.

#### Tags

- Tags begin with a `@`
- Tag names must obey variable naming rules
- Tags are case insensitive
- There must be no leading space between the `@` and the tag name
- Tags must come on the same single line of the description, trailing
  the quoted description

###### Unacceptable (invalid variable name)

```transactions
@for$za             # invalid: contains invalid var-char dollar sign (`$`)
@CanIDeductThis?    # invalid: contains invalid var-char question mark (`?`)
@                   # invalid: missing tag name
```

###### Acceptable

```transactions
@for-business-luncheon
```

```transactions
@for-business-luncheon @deductible
```

#### Exclamation Marks

- Description lines can be optionally accompanied with one or more
  exclamation marks (`!`)
- Like tags, at least one leading whitespace must precede the exclamation
  marks
- Exclamation marks may appear clustered together (`!!!`), separated
  by whitespace or both (`! !! ! !!!`)
- Exclamation marks may also appear intermixed with tags, separated
  by whitespace (`! @tag1 !!!! @tag2`)

###### Unacceptable (exclamation point is followed by unrecognized char)

```transactions
!a
```

###### Acceptable

```transactions
! !! ! !!!
!! @tag1 !!! @tag2
```


Descriptions
------------

- Transaction descriptions are optional
- Transaction descriptions, when given, follow TOML string rules. The
  description can appear all on one line within a pair of double quotes
  (`"this"`), triple doubles (`"""this"""`), single quotes (`'this'`)
  or triple singles (`'''this'''`). Triple quote form allows for
  multiline text.
- There must be at least one whitespace or newline between the date and
  the description, or a metainfo and the description.

#### Unacceptable (transaction description not surrounded in quotes)

```
2014-01-01 I started the year with $1000 in Bankwest cheque account
```

#### Unacceptable (description in quotes not contained on one line)

```
2014-01-01 'I started the year \
            with $1000 in Bankwest \
            cheque account'
2014-01-01 "I started the year \
            with $1000 in Bankwest \
            cheque account"
```

#### Unacceptable ()

#### Acceptable

```
2014-01-01 "I started the year with $1000 in Bankwest cheque account"

2014-01-01 'Single quotes work too'

2014-01-01 '''Triple'd singles with TOML string literal multiline rules'''

2014-01-01 """Triple'd doubles with TOML string basic multiline rules"""

2014-01-01 # descriptions are optional

2014-01-01
'You can do this'

2014-01-01
"You can put the description on the line following the date"

2014-01-01 """
Description here.
"""

2014-01-01
"""
Description here."""

2014-01-01
"""
Description here.
"""

2014-01-01 @tag1 @tag2
"""
Description here.
"""
@tag3 @tag4

2014-01-01
@tag1 @tag2
"""
Description here.
"""
```


Postings
--------

- Postings must appear one after the other, separated by newline
- Comment lines and blank lines are allowed in between postings
- Whitespace is not significant. Postings do not have to align by column
  and do not need to be indented.


Silos
-----

- Accepted silo names
  - Asset / Assets
  - Expense / Expenses
  - Income / Revenue / Revenues
  - Liability / Liabilities
  - Equity / Equities
- Silos are case-insensitive
  - asset / assets
  - expense / expEnSeS
  - income / revENuE / Revenues
  - liability / liabilitiEs
  - Equity / equitieS

#### Unacceptable (use of unsupported silo name)

```
MyCustomSilo:FooEntity:BarSubaccount
```

#### Acceptable

```
Assets:FooEntity:BarSubaccount
```


Entities
--------

- At least one entity must be listed, and must appear directly after
  main account (`Assets`, `Expenses`, `Income`, `Liabilities`, or
  `Equity`)
- Entity names are case-insensitive
- Entities can contain letters (`A-Za-z`), numbers (`0-9`), dashes (`-`)
  and underscores (`_`)
- Entities cannot contain whitespace or any special characters besides
  `-` and `_`
- Entities cannot be named reserve words
  - silo names: assets, expenses, income, liabilities, equity
  - top-level config vars: base-costing, base-currency

#### Unacceptable (no entity given)

```transactions
Assets
```

#### Unacceptable (entities cannot contain whitespace)

```
Assets:Chase Investment Bank
```

#### Unacceptable (entities cannot be named a reserved word)

```
Assets:Assets
Assets:base-currency
```

#### Acceptable

```transactions
Assets:ChaseInvestmentBank
```


Subaccounts
-----------

- Subaccounts are optional
- Subaccount names are case-insensitive
- Subaccounts must be separated by `:`

```
Assets:Bankwest             # Bankwest is interpreted as an entity you own
Assets:Personal:Bankwest    # Bankwest is interpreted as a subaccount owned by you personally
```

#### Unacceptable (subaccounts cannot contain special chars besides `-` and `_`)

```
Assets:MyEntity:Bank.of.America:Checking
Assets:MyEntity:Bank\ of\ America:Checking
Assets:MyEntity:C4$H
```

#### Acceptable

```
Assets:Personal:Bankwest:Cheque
```


Numbers
-------

- TOML number rules are generally adhered to. No leading zeros. Numbers
  can contain underscores so long as each underscore is surrounded by
  a digit. No commas. Bare decimals (`.5`) not allowed, must contain zero
  (`0.5`).
- A dot following a number can only be a decimal point if the following
  character is a digit
- Fractions (`½`) aren’t allowed.
- Scientific notation (`1.23e3`) isn’t allowed.
- Numbers in posting amount sections must provide an asset or currency
  code.
- Negative numbers must avoid giving whitespace between the negating
  `-` character and one of either the asset symbol or asset quantity.

#### Unacceptable (lack of currency code / asset code)

```
1000
1000.00
$1000
$1000.00
```

#### Unacceptable (trailing decimal point)

```
20. USD
$20. USD
USD 20.
```

#### Unacceptable (unsupported use of scientific notation)

```
2.345e3
```

#### Acceptable

```
1000 USD
1000.00 USD
$1000 USD
$1000.00 USD
USD 1000
USD 1000.00
USD $1000
USD $1000.00
```

#### Acceptable

```
-500 USD
-$500 USD
$-500 USD
```

#### Unacceptable (whitespace appears after negative sign)

```
- 500 USD
- $500 USD
```


Exchange Rates
--------------

- Exchange rates are optional
- Exchange rates must be preceded by an `@` symbol and at least one
  whitespace
- Number syntax conventions apply to the given numeric rate


#### Acceptable

```
@ $830.024 USD
@    $830.024 USD
@ 830.024 USD
@ USD 830.024
```

#### Unacceptable (missing leading `@` symbol and at least one whitespace)

```
$830.024 USD
USD 830.024
@USD 830.024
```


Comments
--------

- Comments begin with a `#`
- Comments can appear anywhere
- There is no special multiline comment syntax


Includes
--------

- include separate transaction journal files by writing `include
  'path/to/file/without/extension'` with no leading whitespace
- included files must have `.txn` extension, but include directives
  in transaction journals must leave off the extension, as the `.txn`
  extension is appended automatically by Nightscape
- filename to include must be surrounded with double quotes or single
  quotes, and follow TOML basic string and literal string rules
  respectively.
- use maximum of one include directive per line
- glob syntax not supported

#### Unacceptable (missing double or single quotes around transaction journal name)

```transactions
include includes/2011
```

#### Unacceptable (more than one include directive given per line)

```transactions
include 'includes/2011' 'includes/2012'
```

#### Unacceptable (warning: glob syntax interpreted literally)

```transactions
include 'includes/*'
```

#### Acceptable

```transactions
include 'includes/2011'
include "includes/2012"
include 'includes/whitespace in transaction journal name is ok'
```
