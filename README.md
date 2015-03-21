Nightscape
==========

Bitcoin double-entry cmdline accounting system (WIP)


Description
-----------

[Nightscape](https://nightscape.com) is a plain text-based
double-entry accounting system for Bitcoin and cryptocurrency, with
a modified [Ledger](http://ledger-cli.org) syntax. Nightscape's
syntax was inspired by [@mafm](https://github.com/mafm)'s work in
[ledger.py](https://github.com/mafm/ledger.py), e.g.:

```transactions
2013-01-15 I paid my electricity bill.
  Expenses:Electricity        $280.42
  Assets:Bankwest:Cheque     -$280.42
```


Installation
------------

#### Dependencies

- Rakudo Perl 6
- [TOML](https://github.com/Mouq/toml-pm6)


Usage
-----

```bash
$ PERL6LIB=lib ./bin/nightscape.pl examples/sample.transactions
```


Licensing
---------

Nightscape is Copyright (C) 2015, Andy Weidenbaum. Nightscape is
distributed under the terms of the Artistic License 2.0. For more details,
see the full text of the license in the file LICENSE.
