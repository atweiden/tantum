use v6;
use Nightscape::Entry;
use Nightscape::Entry::Header;
use Nightscape::Entry::Posting;
use Nightscape::Entry::Posting::Account;
use Nightscape::Entry::Posting::Amount;
use Nightscape::Entry::Posting::Amount::XE;
use Nightscape::Types;
unit class Nightscape::Parser::Actions;

my Int $entry_number = 0;

method iso_date($/)
{
    try
    {
        # make valid ISO 8601 date or exit with an error
        make Date.new("$/");
        CATCH { say "Sorry, invalid date 「$/」"; }
    }
}

method tag($/)
{
    # make tag (with leading @ stripped)
    make substr($/, 1, *-0);
}

method important($/)
{
    # make important the quantity of exclamation marks
    make $/.chars;
}

method header($/)
{
    # entry id
    my Int $id = $entry_number;

    # entry date
    my Date $date = $<iso_date>».made.pairs[0].value;

    # entry description
    my Str $description;
    $description = substr($<description>, 1, *-1).trim if $<description>;

    # entry importance
    my Int $important = [+] $<important>».made // 0;

    # entry tags
    my VarName @tags = $<tag>».made // Nil;

    # entry eol comment
    my Str $eol_comment;
    $eol_comment = substr($<eol_comment>, 1, *-0).trim if $<eol_comment>;

    # make entry header
    make Nightscape::Entry::Header.new(
        :$id,
        :$date,
        :$description,
        :$important,
        :@tags,
        :$eol_comment
    );
}

method account($/)
{
    # silo (assets, expenses, income, liabilities, equity)
    my Silo $silo = Nightscape::Types.mksilo: $<silo>.uc;

    # entity
    my VarName $entity = $<entity>.Str;

    # subaccount
    my VarName @subaccount = $<account_sub>.list».Str // Nil;

    # make account
    make Nightscape::Entry::Posting::Account.new(
        :$silo,
        :$entity,
        :@subaccount
    );
}

method exchange_rate($/)
{
    # commodity symbol
    my Str $commodity_symbol;
    $commodity_symbol = $<commodity_symbol>.Str if $<commodity_symbol>;

    # commodity code
    my CommodityCode $commodity_code = $<commodity_code>.Str;

    # commodity quantity
    my Quantity $commodity_quantity = $<commodity_quantity>.abs;

    # make exchange rate
    make Nightscape::Entry::Posting::Amount::XE.new(
        :$commodity_symbol,
        :$commodity_code,
        :$commodity_quantity
    );
}

method amount($/)
{
    # commodity symbol
    my Str $commodity_symbol;
    $commodity_symbol = $<commodity_symbol>.Str if $<commodity_symbol>;

    # commodity code
    my CommodityCode $commodity_code = $<commodity_code>.Str;

    # commodity quantity
    my Quantity $commodity_quantity = $<commodity_quantity>.abs;

    # commodity minus
    my Str $commodity_minus;
    $commodity_minus = $<commodity_minus>.Str if $<commodity_minus>;

    # exchange rate
    my Nightscape::Entry::Posting::Amount::XE $exchange_rate =
        $<exchange_rate>».made.pairs[0].value // Nil;

    # make amount
    make Nightscape::Entry::Posting::Amount.new(
        :$commodity_code,
        :$commodity_quantity,
        :$commodity_symbol,
        :$commodity_minus,
        :$exchange_rate
    );
}

method posting($/)
{
    # account
    my Nightscape::Entry::Posting::Account $account =
        $<account>».made.pairs[0].value;

    # amount
    my Nightscape::Entry::Posting::Amount $amount =
        $<amount>».made.pairs[0].value;

    # debit / credit
    my DrCr $drcr = Nightscape::Types.mkdrcr: $amount.commodity_minus.Bool;

    # make posting
    make Nightscape::Entry::Posting.new(
        :$account,
        :$amount,
        :$drcr
    );
}

method entry($/)
{
    # header
    my Nightscape::Entry::Header $header = $<header>».made.pairs[0].value;

    # postings
    my Nightscape::Entry::Posting @postings = @<posting>».made.list.values;

    # posting comments
    my Str @posting_comments =
        $<posting_comment>».Str».map({ try {substr($_, 1, *-0).trim} }) // Nil;

    # verify entry is limited to one entity
    my VarName @entities;
    push @entities, $_.account.entity for @postings;
    die "Sorry, only one entity per journal entry allowed"
        if @entities.grep({ $_ ~~ @entities[0] }).elems != @entities.elems;

    # make hash intended to become Entry class
    make %(
        :$header,
        :@postings,
        :@posting_comments
    );
    $entry_number++;
}

method journal($/)
{
    # blank line
    my Bool $is_blank_line = $<blank_line>.Bool;

    # comment line
    my Str $comment_line;
    $comment_line =
        try {substr($<comment_line>, 1, *-0).trim} if $<comment_line>;

    if $<entry>
    {
        # journal entry
        my %entry = $<entry>».made;
        my Nightscape::Entry::Header $header = %entry<header>;
        my Nightscape::Entry::Posting @postings = %entry<postings>.list;
        my Str @posting_comments = %entry<posting_comments>.list;

        # make entry
        make Nightscape::Entry.new(
            :$header,
            :@postings,
            :@posting_comments
        );
    }
}

method TOP($/)
{
    make $<journal>».made;
}

# vim: ft=perl6
