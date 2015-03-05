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


Postings
--------

- Postings must be indented with leading whitespace (one or more whitespaces)
- Other than leading whitespace to denote postings, whitespace is not
  significant. Postings do not have to align by column.
- Postings must appear one after the other


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

- Transaction descriptions must appear all on one line.

#### Unacceptable (transaction description is not contained on one line)

```
2014-01-01 I started the year \
           with $1000 in Bankwest \
           cheque account
```

#### Acceptable

```
2014-01-01 I started the year with $1000 in Bankwest cheque account
```


Accounts
--------

- No whitespace is allowed within account names
- Accounts must be separated by `:`


Numbers
-------

- Numbers for CR/DR purposes must provide an asset or currency code.
- Scientific notation isn’t allowed.
- Negative numbers should avoid spaces between the negating `-`
  character and the rest of the number.

#### Unacceptable (lack of asset asset or currency code):

```
1000
1000.00
$1000
$1000.00
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

- Comments begin with a `;`
- Comments can appear anywhere
- There is no special multiline comment syntax
