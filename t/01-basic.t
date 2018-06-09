use v6;
use lib 'lib';
use Tantum;
use Tantum::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
use lib 't/lib';
use TantumTest;

my %setup = TantumTest.setup;
my Tantum $tantum .= new(|%setup);
my List:D $sync = $tantum.sync;
$sync.perl.say;

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
