# Tantum

Double-entry accounting system


## Installation

### Dependencies

- Rakudo Perl6
- [Config::TOML](https://github.com/atweiden/config-toml)
- [File::Presence](https://github.com/atweiden/file-presence)
- [mktxn](https://github.com/atweiden/mktxn)

### Test Dependencies

- [Peru](https://github.com/buildinspace/peru)

To run the tests:

```
$ git clone https://github.com/atweiden/tantum && cd tantum
$ peru --file=.peru.yml --sync-dir="$PWD" sync
$ PERL6LIB=lib prove -r -e perl6
```


## Licensing

This is free and unencumbered public domain software. For more
information, see http://unlicense.org/ or the accompanying UNLICENSE file.
