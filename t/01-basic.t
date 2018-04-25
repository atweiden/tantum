use v6;
use lib 'lib';
use Nightscape;
use lib 't/lib';
use NightscapeTest;
# use Test;

# plan(1);

# subtest({
    my %setup = NightscapeTest.setup;
    my Nightscape $nightscape .= new(|%setup);
    $nightscape.sync;
# });

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
