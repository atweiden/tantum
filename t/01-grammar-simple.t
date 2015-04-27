use v6;
use lib 'lib';
use Test;
use Nightscape::Parser::Grammar;

plan 1;

my $content = q:to/EOTX/;
# this is a preceding comment
# this is a second preceding comment
2014-01-01 "I started the year with $1000 in Bankwest cheque account" @TAG1 @TAG2 # EODESC COMMENT
  # this is a comment line
  Assets:Personal:Bankwest:Cheque    $1000.00 USD
  # this is a second comment line
  Equity:Personal                    $1000.00 USD # EOL COMMENT
  # this is a third comment line
# this is a stray comment
# another


2014-01-02 "I paid Exxon Mobile $10 for gas from Bankwest cheque account"
  Expenses:Personal:Fuel             $10.00 USD
  Assets:Personal:Bankwest:Cheque   -$10.00 USD

2014-01-02
  Expenses:Personal:Fuel             $20.00 USD
  Assets:Personal:Bankwest:Cheque   -$20.00 USD


# ending comment block
    # ending comment block
# ending comment block
    # ending comment block
# ending comment block
    #
EOTX

{
    my $match = Nightscape::Parser::Grammar.parse($content);
    is($match.WHAT.perl, 'Match', 'Parses simple journal successfully');
}

# vim: ft=perl6
