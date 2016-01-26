use v6;
use TXN::Parser::Grammar;
unit class Nightscape::Types;

subset AcctName of Str is export where
{
    TXN::Parser::Grammar.parse($_, :rule<acct-name>);
}

subset AssetsAcctName of AcctName is export where * ~~ / ^ASSETS ':' \N+$ /;

subset AssetCode of Str is export where
{
    TXN::Parser::Grammar.parse($_, :rule<asset-code>);
}

subset GreaterThanZero of FatRat is export where * > 0;

subset Instruction of Hash is export where
{
    .keys.sort ~~ <acct-name newmod posting-id quantity-to-debit xe>;
}

subset LessThanZero of FatRat is export where * < 0;

subset Price of FatRat is export where * >= 0;

subset Quantity of FatRat is export where * >= 0;

subset VarName of Str is export where
{
    TXN::Parser::Grammar.parse($_, :rule<var-name>);
}

subset xxHash of Int is export;

enum AssetFlow is export <ACQUIRE EXPEND STABLE>;

enum Costing is export <AVCO FIFO LIFO>;

enum DecInc is export <DEC INC>;

enum HoldingPeriod is export <SHORT-TERM LONG-TERM>;

enum NewMod is export <NEW MOD>;

enum Silo is export <ASSETS EXPENSES INCOME LIABILITIES EQUITY>;

class EntryID is export
{
    has Int $.number;
    has xxHash $.xxhash;

    # causal text from transaction journal
    has Str $.text;

    method canonical() returns Str
    {
        $.number ~ ':' ~ $.xxhash;
    }
}

class PostingID is export is EntryID
{
    # parent EntryID
    has EntryID $.entry-id;
}

# compare EntryIDs
multi sub infix:<==>(EntryID:D $a, EntryID:D $b) is export returns Bool:D
{
    # entry numbers and xxhashes must be identical
    $a.number == $b.number && $a.xxhash == $b.xxhash;
}

# compare PostingIDs
multi sub infix:<==>(PostingID:D $a, PostingID:D $b) is export returns Bool:D
{
    # parent EntryIDs must be identical
    $a.entry-id == $b.entry-id &&
        $a.number == $b.number && $a.xxhash == $b.xxhash;
}

sub mkasset-flow(FatRat:D $d) is export returns AssetFlow:D
{
    if $d > 0
    {
        ACQUIRE;
    }
    elsif $d < 0
    {
        EXPEND;
    }
    else
    {
        STABLE;
    }
}

sub mkdecinc(Str $plus-or-minus) is export returns DecInc:D
{
    $plus-or-minus ~~ '-' ?? DEC !! INC;
}

class X::Nightscape::Entry is Exception
{
    has EntryID $.entry-id;

    method message()
    {
        say qq:to/EOF/;
        In entry number {$.entry-id.number}:

        「{$.entry-id.text}」
        EOF
    }
}

class X::Nightscape::Entry::NotBalanced is X::Nightscape::Entry {*}

class X::Nightscape::Entry::XEMismatch is X::Nightscape::Entry {*}

class X::Nightscape::Posting is Exception
{
    has PostingID $.posting-id;

    method message()
    {
        say qq:to/EOF/;
        In entry number {$.posting-id.entry-id.number}:

        「{$.posting-id.entry-id.text}」

        In posting number {$.posting-id.number}:

        「{$.posting-id.text}」
        EOF
    }
}

class X::Nightscape::Posting::XEBad is X::Nightscape::Posting {*}

class X::Nightscape::Posting::XEMissing is X::Nightscape::Posting {*}

class X::Nightscape::Entity::Holding::Expend::OutOfStock is X::Nightscape::Entry {*}

# vim: ft=perl6 fdm=marker fdl=0
