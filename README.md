Nightscape
==========

Double-entry cmdline accounting system with support for automatic capital
gains / losses calculation using an intuitive syntax.

Nightscape's syntax was inspired by [@mafm](https://github.com/mafm)'s
work in [ledger.py](https://github.com/mafm/ledger.py), e.g.:

```transactions
2013-01-15 I paid my electricity bill.
  Expenses:Electricity        $280.42
  Assets:Bankwest:Cheque     -$280.42
```


Illustrated Use Cases
---------------------

#### Asset dispositions

Nightscape syntax:

```transactions
2013-11-12 "I sold 10 BTC for $10,000.00 USD, at a price of $1000 USD/BTC"
  Assets:FooCorp:Bitstamp     $10000 USD
  Assets:FooCorp:Bitstamp    -฿10.00 BTC @ $1000 USD
```

Alternate text-based bookkeeping approaches, such as
[Ledger](http://ledger-cli.org) transaction journals, require a more
elaborate syntax:

```transactions
2013-11-12 "I sold 10 BTC for $10,000.00 USD, at a price of $1000 USD/BTC"
  Assets:FooCorp:Bitstamp         $10000.0 USD
  Income:FooCorp:CapitalGains     $9950.00 USD
  Assets:FooCorp:Bitstamp        -฿1.23456789 BTC @ $4.05000003686 USD
  Assets:FooCorp:Bitstamp        -฿2.34567890 BTC @ $4.26315809892 USD
  Assets:FooCorp:Bitstamp        -฿3.45678901 BTC @ $4.339287112 USD
  Assets:FooCorp:Bitstamp        -฿2.96296420 BTC @ $6.74999718188 USD
```

... wherein you may have sold 10 BTC, but, of the 10 BTC being sold,
X% was acquired at price $A, Y% was acquired at price $B, and Z% was
acquired at price $C; leading to realized capital gains or losses.

Nightscape automatically translates the simple syntax of the former to
the latter, by ascertaining which basis lot(s) are being expended at
which acquisition price(s), and in turn calculating any realized capital
gains or losses.


Usage
-----

```bash
$ PERL6LIB=lib ./bin/nightscape.pl examples/sample/sample.txn
```


Installation
------------

#### Dependencies

- Rakudo Perl 6
- [Config::TOML](https://github.com/atweiden/config-toml)
- [Digest::xxHash](https://github.com/atweiden/digest-xxhash)
- [JSON::Tiny](https://github.com/moritz/json)

#### Optional Dependencies

- [Pacman](https://www.archlinux.org/pacman/): for querying cached txnpkgs


Licensing
---------

This is free and unencumbered public domain software. For more
information, see http://unlicense.org/ or the accompanying UNLICENSE file.
