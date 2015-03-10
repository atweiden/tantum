Nightscape Syntax
=================

General
-------

- Whitespace only. No tabs.


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
  within either a pair of double quotes ("this") or double curly quotes
  (“that”)

#### Unacceptable (transaction description is not contained on one line)

```
2014-01-01 I started the year \
           with $1000 in Bankwest \
           cheque account
```

#### Unacceptable (transaction description not surrounded in double quotes)

```
2014-01-01 I started the year with $1000 in Bankwest cheque account
```

#### Acceptable

```
2014-01-01 "I started the year with $1000 in Bankwest cheque account"
2014-01-01 “I started the year with $1000 in Bankwest cheque account”
2014-01-01 # descriptions are optional
```


Postings
--------

- Postings must be indented with two or more leading whitespaces
- Other than leading whitespace to denote postings, whitespace is not
  significant. Postings do not have to align by column.
- Postings must appear one after the other


Accounts
--------

- Accepted main account names
  - Asset / Assets
  - Expense / Expenses
  - Income / Revenue / Revenues
  - Liability / Liabilities
  - Equity / Equities
- Main account names are case-insensitive
  - asset / assets
  - expense / expEnSeS
  - income / revENuE / Revenues
  - liability / liabilitiEs
  - Equity / equitieS
- Subaccount names are case sensitive
- Subaccounts can contain letters (`A-Za-z`), numbers (`0-9`), periods
  (`.`), dashes (`-`) and underscores (`_`)
- Subaccounts cannot contain whitespace or any special characters besides
  `.`, `-` and `_`
- Subaccounts must be separated by `:`

#### Unacceptable (use of unsupported main account name)

```
MyCustomMainAcct:Subaccount:Subaccount
```

#### Unacceptable (subaccounts cannot contain whitespace)

```
Assets:Bank of America:Checking
```

#### Unacceptable (subaccounts cannot contain special chars besides `.`, `-` and `_`)

```
Assets:Bank\ of\ America:Checking
Assets:C4$H
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
- Fractions aren't allowed.
- Scientific notation isn’t allowed.
- Negative numbers should avoid spaces between the negating `-` character
  and one of either the asset symbol or asset quantity.

#### Unacceptable (lack of asset asset or currency code):

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

#### Unacceptable (unsupported use of scientific notation):

```
1e2.45
```

#### Acceptable:

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

#### Acceptable:

```
-500 USD
-$500 USD
$-500 USD
```

#### Unacceptable (whitespace appears after negative sign):

```
- 500 USD
- $500 USD
```


Comments
--------

- Comments begin with a `#`
- Comments can appear anywhere, but trailing comments must have at least
  one leading whitespace
- There is no special multiline comment syntax
