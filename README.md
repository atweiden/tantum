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


Usage
-----

```bash
$ perl6 nightscape.pl
```


Licensing
---------

This is free and unencumbered public domain software. For more
information, see http://unlicense.org/ or the accompanying UNLICENSE file.
