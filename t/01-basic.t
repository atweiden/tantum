use v6;
use lib 'lib';
use Nightscape;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
use lib 't/lib';
use NightscapeTest;

my %setup = NightscapeTest.setup;
my Nightscape $nightscape .= new(|%setup);
my List:D $sync = $nightscape.sync;

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
