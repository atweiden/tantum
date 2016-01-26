Comparisons
===========

A review of other cmdline double-entry accounting systems follows.


[Beancount](https://bitbucket.org/blais/beancount/src)
------------------------------------------------------

The most active and innovative reimplementation of Ledger.

#### Likes

- Opening and closing of accounts

- Hashtags and links
  - The link syntax (`^`) is for marking related transactions
  - Hashtags are a more general solution

- Good ideas WRT `balance` assertions being limited to one currency /
  asset, and only that asset; this instead of converting all commodities
  held at that time back into the base currency. Though would like to
  see this become more configurable.

- `note`: because you should be able to keep your transaction-related
  notes in order, e.g. `2013-11-03 note Liabilities:CreditCard "Called
  about fraudulent card."`

- `document`: because you want to be able to attach scanned receipts to
  a transaction
  - I like the configurable documents directory as a solution for
    relative paths in `document` directive lookups, e.g.
    `option "documents" "/home/joe/stmts"`

- `event`, e.g. `2014-07-09 event "location" "Paris, France"`.
  interesting event ideas: "location", "address", "employer". Good for
  tracking your whereabouts over time.

- attach arbitrary metadata as child elements of posting, avail in
  scripts as dict (`.meta`)

- `include`: for including other journal files

- `open` and `close`: allows you to specify which asset accounts and
  subaccounts are open and closed within a given time period, which is
  helpful in report generation

- `2014-05-25 price IBM   182.27 USD` syntax decent for tracking
  unrealized capital gains/losses over time for informational purposes

- weighted average cost basis method being experimented on, which would
  be a viable option for automatically calculating capital gains:

#### Dislikes

- Only supports one action per day (no date duplicates). You can't repeat
  ISO-DATE + ACTION, e.g. `2014-02-03 balance`. For my logs this could
  cause cascading problems, or I would have to cram together individual
  Bitcoin sends when multiple transfers, between exchanges or between
  wallets, occur on the same day.

- Does not support unicode characters in entries.

- Unintuitive postings syntax. I don’t like the idea of writing
  `-$100.00` to show a $100 *increase* in liabilities. I have the same
  complaint about every cmdline accounting system save for Ledger.py.

- No FIFO/LIFO/AVGCOST method support. Beancount requires manually
  specifying the basis against which capital gains are calculated when
  selling or exchanging assets. I have the same complaint about every
  cmdline accounting system.
  - This is a tedious, manual effort, e.g. `10 SOME {2.02 USD}
    [2012-12-12] @ 2.50 USD`, which requires counting, by hand, remaining
    lots of $2.02 basis assets acquired on 2012-12-12. Particularly with
    Bitcoin trading, this would be much better handled using the FIFO
    method, which is something the software should be able to do
    automatically. Without a FIFO mode, most people will end up using FIFO
    to account for Bitcoin transactions, except they’ll have to do it
    by hand, which is very error-prone and tedious work. Since there are
    very specific rules about when you can pick and choose lots to sell,
    it isn’t clear if lot sales accounting is even possible with bitcoin
    except for the rare instances when you can trace individual inputs
    and outputs to specific sales. This is much easier said than done. No
    current Bitcoin exchanges support this. FIFO/LIFO/AVGCOST methods
    are required.

- Syntax additions of `pushtag` and `poptag` break with the syntax of
  normal journal entries

- Maybe make start-of-line `balance` ACTIONs possible along with `pushtag`
  and `poptag` to be consistent?

- Not sure how I feel about the idea of a `pad` account. It seems
  unintuitive.

- I don’t like how the `note` syntax forces you to associate the `note`
  with a subaccount. Subaccount should be optional. Could this be done
  with a different syntax?

- I think `document` should be inscribed within the transaction posting
  itself, or get posted similar to `note`s.
  - I also think the `document` directory option should be configured
    in an INI config file. It shouldn’t clutter the logs.

- Rather than cluttering the logs with price info, e.g.  `2014-07-09 price
  HOOL  579.18 USD` the price data should be put in a separate text file,
  probably in CSV format similar to [Coindesk’s
  exports](http://www.coindesk.com/price)
  - price data preferences would be better to place in config files,
    with the currency pair the data is good for, and optionally a date
    range or hash tag that takes price data from the specified CSV
    - could also be extended to support exports from a variety of
      sources, e.g.:

    [Price Feed]
    currency-pair
    data-location
    data-source (optional)
    date-range (optional)
    tag (optional)

- Other options that should be recorded in INI config file

    option "title" "Joe Smith’s Personal Ledger"
    option "name_assets"       "Assets"
    option "name_liabilities"  "Liabilities"
    option "name_equity"       "Equity"
    option "name_income"       "Income"
    option "name_expenses"     "Expenses"

- Options should probably have an `include` directive too


[Ledger](http://ledger-cli.org)
-------------------------------

#### Likes

- Biggest userbase, most stable and longest running

- Multicurrency support
  - Implied exchange rates without having to use the @ syntax for
    detection

- User-defined root account types
  - Multiple entities support

- User-defined variables

- Extensive documentation

- Equity report generation for easier separation of years
  - Generate an equity report for a time period and prepend that equity
    report to the top of the next time period

- Cleared/pending designation
  - You can mark individual postings as cleared or pending, in case one
    “side” of the transaction has cleared, but the other hasn’t yet

- Comments as part of syntax through indentation

- Metadata
  - Payee (inserted as comment metadata)
    - Indicates the person or entity who paid you

- @@ instead of @ if you wish to specify total amount paid or a commodity
  instead of price per unit

- functions, although they could be called with &function(args) to be
  more intuitive

- Embedded regexes for type safe tags, e.g.:

    tag Receipt
      check value =~ /pattern/
      assert value != "foobar"

- Embedded regexes for type safe accounts (would be better in config file)

    account Expenses:Food
      note This account is all about the chicken!
      alias food
      payee ^(KFC|Popeyes)$
      check commodity == "$"
      assert commodity == "$"
      eval print("Hello!")
      default

- Asset names with whitespace and numeric characters possible by
  surrounding with double-quotes

- Data equivalence. But it should be done in a config file. It’s a
  cool feature but not that useful because you’d want to stick with
  the same unit as much as possible to keep logs neat and readable.
  Switching between units could make logs harder to read and could make
  it easier to make mistakes.
    C 1.00 Kb = 1024 b
    C 1.00 Mb = 1024 Kb
    C 1.00 Gb = 1024 Mb
    C 1.00 Tb = 1024 Gb

- `--anon` report gen option: anonymizes accounts and payees, useful
  for filing bug reports

- `--trace`

- `--head`: cause only the first INT txs to be printed

- `--pager` or `LEDGER_PAGER` environment variable: tells ledger to pass
  output to the pager program

#### Dislikes

- Payee; I'd rather optionally declare the payee with @WORD or #HASHTAG
  than make the payee a required field. Beancount gets this right.

- Strange postings syntax, which is justified as follows, quote:

> Why is the Income a negative figure? When you look at the balance totals
> for your ledger, you may be surprised to see that Expenses are a positive
> figure, and Income is a negative figure. It may take some getting used
> to, but to properly use a general ledger you must think in terms of how
> money moves. Rather than Ledger “fixing” the minus signs, let’s
> understand why they are there.
>
> When you earn money, the money has to come from somewhere. Let’s call
> that somewhere “society”. In order for society to give you an
> income, you must take money away (withdraw) from society in order to put
> it into (make a payment to) your bank. When you then spend that money,
> it leaves your bank account (a withdrawal) and goes back to society (a
> payment). This is why Income will appear negative—it reflects the money
> you have drawn from society—and why Expenses will be positive—it
> is the amount you’ve given back. These additions and subtractions
> will always cancel each other out in the end, because you don’t have
> the ability to create new money: it must always come from somewhere,
> and in the end must always leave. This is the beginning of economy,
> after which the explanation gets terribly difficult.

I like Ledger.py’s approach:

    Assets + Expenses = Liability + Income + Equity

When you receive money as salary, that's income, and Income and Assets
both increase.

Here's how the original Ledger records this transaction:

    9/29    My Employer
      Assets:Checking     $500.00
      Income:Salary       $-500.00

Here's how Ledger.py records it:

    2015-09-29
      Assets:Checking     $500.00
      Income:Salary       $500.00

Ledger.py marks Income postings as a negative amount when making internal
balance calculations. This allows for the more intuitive journal entry
syntax.

Account   | Multiplier
---       | ---
Assets    |  1
Expenses  |  1
Liability | -1
Income    | -1
Equity    | -1

- Very complex. The syntax is insane in many places so as to make Ledger
  more of a general solution. This comes at the cost of readability
  and usability.
  - e.g. periodic transactions, think: macro. Macros should have no place
    in a plain text accounting log. It makes the text file very hard for
    a human to read through. Anything like that should be handled with
    a dedicated GUI and exported to plain text afterwards
  - e.g. expressions that perform calculations within ledger
    entries. The parser should do as few calculations as possible.
  - e.g. embedded python

- I dislike the shorthand syntax used. leaving out the amounts transacted
  and allowing ledger to fill in the difference saves almost no typing,
  and it can make log files harder to read

- `apply account`: breaks from normal syntax and doesn’t work too well
  in text files where you can scroll down the page a lot and forget
  you’re supposed to be making txs under Company XYZ since you ran
  `apply account` 1000 lines up the file.

- Ledger makes assumptions about currencies vs commodities by syntax
  cues which are unreliable, and would be better handled with config
  options

> Ledger will examine the first use of any commodity to determine how that
> commodity should be printed on reports. It pays attention to whether the
> name of commodity was separated from the amount, whether it came before
> or after, the precision used in specifying the amount, whether thousand
> marks were used, etc. This is done so that printing the commodity looks
> the same as the way you use it.


[Ledger.py](https://github.com/mafm/ledger.py)
----------------------------------------------

#### Likes

- Best, most human-readable syntax of any cmdline accounting solution.

#### Dislikes

- Very limited feature set

- Doesn’t support multiple currencies


[HLedger](https://github.com/simonmichael/hledger)
--------------------------------------------------

#### Likes

- Web interface with advanced search feature

- Cmdline interface improves upon Ledger-CLI

- Flexible syntax

> hledger supports flexible decimal point and digit group separator
> styles, to support international variations. Numbers can use either
> a period (.) or a comma (,) as decimal point. They can also have
> digit group separators at any position (eg thousands separators)
> which can be comma or period - whichever one you did not use as a
> decimal point. If you use digit group separators, you must also include
> a decimal point in at least one number in the same commodity, so that
> hledger knows which character is which. Eg, write $1,000.00 or $1.000,00

- Depth limiting

> With the `--depth N` option, commands like `account`, `balance` and
> `register` will show only the uppermost accounts in the account tree,
> down to level `N`. Use this when you want a summary with less detail.

- Interactive entry mode

> The `add` command prompts interactively for new transactions, and
> appends them to the journal file. Just run hledger `add` and follow
> the prompts. You can add as many transactions as you like; when you
> are finished, enter `.` or press control-d or control-c to exit.

- Query expressions: same advanced search queries as used in the web
  ui’s search box

- hledger sorts an account's postings and assertions first by date
  and then (for postings on the same day) by parse order. Note this
  is different from Ledger, which sorts assertions only by parse
  order. (Also, Ledger assertions do not see the accumulated effect of
  repeated postings to the same account within a transaction.)
  - So, hledger balance assertions keep working if you reorder
    differently-dated transactions within the journal. But if you reorder
    same-dated transactions or postings, assertions might break and
    require updating. This order dependence does bring an advantage:
    precise control over the order of postings and assertions within a
    day, so you can assert intra-day balances.

- You can include tags (labels), optionally with values, in transaction
  and posting comments, and then query by tag. This is like Ledger's
  metadata feature, except hledger's tag values are simple strings.

- optional status flag, which can be empty or `!` or `*` (meaning
  "uncleared", "pending" and "cleared", or whatever you want)

#### Dislikes

- Web interface leaves much to be desired

- Doesn’t compile

- Syntax

- Based on how you format amounts, hledger will infer canonical display
  styles for each commodity, and use these when displaying amounts in
  that commodity
  - The canonical style is generally the style of the first posting
    amount seen in a commodity. However the display precision will be
    the highest precision seen in all posting amounts in that commmodity.


[Penny](https://github.com/massysett/penny)
-------------------------------------------

#### Dislikes

- Syntax.
