use v6;
use lib 'lib';
use Test;
use Nightscape::Parser;

plan 1;

my $content = q:to/EOTX/;
; this is a preceding comment
; this is a second preceding comment
2014-01-01 "I started the year with $1000 in Bankwest cheque account #TAG1 #TAG2" ; EODESC COMMENT
  ; this is a comment line
  Assets:Personal:Bankwest:Cheque    $1000.00 USD
  ; this is a second comment line
  Equity:Personal                    $1000.00 USD ; EOL COMMENT
  ; this is a third comment line
; this is a stray comment
; another


2014-01-02 "I paid Exxon Mobile $10 for gas from Bankwest cheque account"
  Expenses:Personal:Fuel             $10.00 USD
  Assets:Personal:Bankwest:Cheque   -$10.00 USD

2014-01-02
  Expenses:Personal:Fuel             $20.00 USD
  Assets:Personal:Bankwest:Cheque   -$20.00 USD

2014-01-03 "I bought ฿0.80000000 BTC on Coinbase.com for $670.66 USD at a price of $830.024 USD/BTC with a fee of $6.64 USD"
  Assets:Personal:Coinbase:BTC           ฿0.80000000 BTC @ $830.024 USD
  Expenses:Personal:CoinbaseFee          $6.64 USD
  Assets:Personal:Bankwest:Cheque       -$670.66 USD


; ending comment block
    ; ending comment block
; ending comment block
    ; ending comment block
; ending comment block
        ;
EOTX

{
    my $match = Nightscape::Parser.parse($content);
    is($match.WHAT.perl, 'Match', 'Parses multicurrency journal successfully');
}

# vim: ft=perl6
