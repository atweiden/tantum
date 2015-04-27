Components Required
===================

- Syntax
- Config
- Parser
- Validation
- Logic
- Reports

Syntax
------

Syntax inspired by [Ledger.py](https://github.com/mafm/ledger.py),
[Beancount](https://bitbucket.org/blais/beancount/src) and
[HLedger](https://github.com/simonmichael/hledger).

#### Virtual Accounts

**Virtual Accounts**. These are z-index accounts that don't actually
exist but allow you to essentially create labels that you can track over
time. Potentially useful for budgeting, e.g.:

```transactions
2014-01-01 "I receive paycheck of $20000.00 USD"
  Assets:Checking        $20000.00
  Income:Job             $20000.00
  _Budget:Electronics    $10000.00
  _Budget:Pets           $10000.00
```

```transactions
2014-03-25 "Payment for books (paid from Checking)"
  Expenses:Books         $100.00
  Assets:Checking        $-100.00
  _Budget:School         $-100.00
```

#### Links

**Links**. Come in handy if `include`-ing multiple journals, wherein
certain entries are related, note the `@Jan2014Loan[]` array syntax.

```transactions
2014-01-02 "I loaned the business $100.00 USD, to be repaid in full no later than three years following today's date (i.e. by or on 2017-01-02), plus the annual AFR as of January 2014 (0.25%), compounded annually" #Bankwest-Personal #loans-receivable @Jan2014Loan[0]
  Assets:Personal:AccountsReceivable     $100.00 USD
  Assets:Personal:Bankwest:Cheque       -$100.00 USD

2014-01-02 "The business received a loan, from shareholder Andrew Weidenbaum, in the amount of $100.00 USD, repayable in full no later than three years following today's date (i.e. by or on 2017-01-02), plus the annual AFR as of January 2014 (0.25%), compounded annually" #loans-payable #Bankwest-Business @Jan2014Loan[1]
  Assets:Business:Bankwest:Cheque        $100.00 USD
  Liabilities:Business:AccountsPayable   $100.00 USD
```

When both files are `include`d together during report generation,
the personal side of the loan will appear before the corporate side,
reflecting order of array elements.


Config
------

**INI config**

- Configurable tax treatment by account type for accurate report generation
  - Generic
  - CapitalGains
  - CapitalLosses
  - Dividends
  - Interest
  - Gifts
  - Donations
  - GamblingWinnings

- Configurable price data
  - Entity-specific pricing data

if you don't specify:

```toml
[EntityNamedFoo.Currencies.BTC.Prices.USD]
```

for `[EntityNamedFoo]`, then Nightscape will default to looking for
exchange rate pricing in the config_file section titled:

```
[Currencies.$aux_currency_code.Prices.$entity_base_currency_code]
```

```toml
[Currencies.BTC.Prices.USD]
```

if you specify:

```toml
[EntityNamedFoo.Currencies.BTC.Prices.USD]
"2014-01-01" = 770000.4357
```

then Nightscape will ignore all other pricing data contained in the
config_file for EntityNamedFoo’s transactions, and exclusively read
pricing directives given under EntityNamedFoo.

alternatively, if you specify:

```toml
[EntityNamedFoo.Currencies.BTC.Prices.USD]
use-global-pricing = True
```

then prices in the global Currencies group will merge with prices given
for EntityNamedFoo, with EntityNamedFoo pricing taking precedence.

implementation detail: be sure that only the pricing pairs (`"2014-01-01"
= 770.4357`) merge, with any price-file directives resolving to the
pricing pairs before merger.

  - Tag-specific pricing data

["@coinbase".Currencies.BTC.Prices.USD]

- Configurable documents directory


Parser
------

Example log format:

```transactions
2013-01-01 I began the year with $1000 in my cheque account.
  Assets:Bankwest:Cheque      $1,000
  Equity:OpeningBalances      $1,000

2013-01-05 I bought some groceries and paid using the cheque account.
  Expenses:Food:Groceries     $98.53
  Assets:Bankwest:Cheque     -$98.53

2013-01-10 I bought some petrol, and paid using a credit card.
  Expenses:Motor:Fuel         $58.01
  Liabilities:Bankwest:Visa   $58.01

2013-01-15 I paid my electricity bill.
  Expenses:Electricity        $280.42
  Assets:Bankwest:Cheque     -$280.42
```

From this, we need to parse:

```
├── Account
├── Date
├── Description
└── Posting
```

#### Account

We need the ability to discern accounts (`Assets`, `Expenses`,
`Liabilities`, `Income`, `Equity`), as well as arbitrarily named
subaccounts from colon (`:`) separated words, e.g. `Expenses:Electricity`.

#### Date

Date of transaction.

#### Description

Description of transaction.

#### Posting

Debits and credits.


Validation
----------

Each entry should balance. [@mafm](https://github.com/mafm)’s code
does this with a table:

Account     | Multiplier
---         | ---
Assets      |  1
Expenses    |  1
Liabilities | -1
Income      | -1
Equity      | -1
```

For multicurrency entries, or when an alternative currency/asset symbol is
detected as opposed to the default currency symbol, the parser should
attempt to resolve the posting value in terms of the default currency for
capital gains calculations.

It should be possible to pay for BTC in EUR, even if your default currency
is USD. In which case, additions and subtractions to EUR reserves should
occur without elaborate by-hand notation of capital gains/losses. The
values should balance in terms of the default currency, and capital
gains/losses calculated on demand.

Whenever an asset of one type other than the default currency is moved,
sold or exchanged, an exchange rate is scanned for *unless and only
unless* the asset in question is moved between asset accounts owned
by the same entity. If the exchange rate is scanned for and not found,
Nightscape should raise an exception. If the exchange rate is scanned
for and successfully found, Nightscape should ensure that the exchange
rate is quoted in terms of the base currency:

```transactions
2014-12-01 "The business bought ฿0.10000000 BTC on Coinbase.com for $77.99 USD at a price of $771.46 USD/BTC with a fee of $0.84 USD"
  Assets:Business:Coinbase:BTC           ฿0.10000000 BTC @ $771.46 USD/BTC
  Expenses:Business:CoinbaseFee          $0.84 USD
  Assets:Business:Bankwest:Cheque       -$77.99 USD
```

If the exchange rate is not quoted in terms of the base currency,
Nightscape should raise an exception.

Alternatively, in cases where one non-default commodity is used to pay
for another non-default commodity, syntax is checked to ensure the "base"
non-default commodity is expressed in the true default commodity, e.g.:

```transactions
2015-01-01 "I exchanged 1 BTC for 200 LTC"
  Assets:LTC     200  LTC
  Assets:BTC    -1.00 BTC @ $395.00
```

Works behind the scenes to compute $1.975 as basis for the LTC


Logic
-----

- Track FIFO basis


Reports
-------

- Generate reports
