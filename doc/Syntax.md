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


Headers
-------

- Entry headers must begin at column 0 with no leading whitespace or indentation

#### Unacceptable (header has leading whitespace or indentation)

```
  2014-01-01 I started the year with $1000 in Bankwest cheque account
    Assets:Personal:Bankwest:Cheque    $1000.00 USD
    Equity:Personal                    $1000.00 USD
```

#### Acceptable

```
2014-01-01 I started the year with $1000 in Bankwest cheque account
  Assets:Personal:Bankwest:Cheque    $1000.00 USD
  Equity:Personal                    $1000.00 USD
```


Dates
-----

- Must be valid ISO 8601 (YYYY-MM-DD)

#### Unacceptable (not ISO 8601)

```
1-1-2015
1/1/2015
2015/01/01
Jan 1st, 2015
```

#### Acceptable

```
2015-01-01
```


Descriptions
------------

- Transaction descriptions are optional
- Transaction descriptions, when given, must appear all on one line,
  within a pair of double quotes ("this") or single quotes ('this')

#### Unacceptable (transaction description is not contained on one line)

```
2014-01-01 I started the year \
           with $1000 in Bankwest \
           cheque account
```

#### Unacceptable (transaction description not surrounded in double or single quotes)

```
2014-01-01 I started the year with $1000 in Bankwest cheque account
```

#### Acceptable

```
2014-01-01 "I started the year with $1000 in Bankwest cheque account"
2014-01-01 'Single quotes work too'
2014-01-01 # descriptions are optional
```


Postings
--------

- Postings must be indented with two or more leading whitespaces
- Other than leading whitespace to denote postings, whitespace is not
  significant. Postings do not have to align by column.
- Postings must appear one after the other


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

- Numbers for CR/DR purposes must provide an asset or currency code.
- Numbers for CR/DR purposes must not contain commas or underscores.
- Numbers between -1 and 0, and 0 and 1 for CR/DR purposes need not
  contain a leading zero before the decimal place.
- A dot following a number can only be a decimal point if the following
  character is a digit
- Fractions (`½`) aren’t allowed.
- Scientific notation (`1.23e3`) isn’t allowed.
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
- Comments can appear anywhere, but trailing comments must have at least
  one leading whitespace
- There is no special multiline comment syntax


Tags
----

- Tags begin with a `@`
- Tag names must obey variable naming rules
- Tags are case insensitive
- There must be no leading space between the `@` and the tag name
- Tags must come on the same single line of the description, trailing
  the quoted description

#### Unacceptable (invalid variable name)

```transactions
@for$za             # invalid: contains invalid var_char dollar sign (`$`)
@CanIDeductThis?    # invalid: contains invalid var_char question mark (`?`)
@                   # invalid: missing tag name
```

#### Acceptable

```transactions
@for_business_luncheon
```

```transactions
@for_business_luncheon @deductible
```


Exclamation Marks
-----------------

- Description lines can be optionally accompanied with one or more
  exclamation marks (`!`)
- Like tags, at least one leading whitespace must precede the exclamation
  marks
- Exclamation marks may appear clustered together (`!!!`), separated
  by whitespace or both (`! !! ! !!!`)
  - Exclamation marks may also appear intermixed with tags, separated
    by whitespace

#### Unacceptable (not a bare exclamation point)

```transactions
!a
```

#### Acceptable

```transactions
! !! ! !!!
```


Includes
--------

- include separate transaction journal files by writing `include
  'path/to/file/without/extension'` with no leading whitespace
- included files must have `.transactions` extension, but include
  directives in transaction journals must leave off the extension,
  as the extension is added automatically
- filename to include must be surrounded with double quotes or single
  quotes
- use maximum of a single include directive per line
- whitespace and utf-8 in filenames is ok
- glob syntax not supported

#### Unacceptable (missing double or single quotes around transaction journal name)

```transactions
include includes/2011
```

#### Unacceptable (leading whitespace present)

```transactions
  include 'includes/2011'
```

#### Unacceptable (more than one include directive given)

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