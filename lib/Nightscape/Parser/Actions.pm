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

    # entry uuid
    use UUID;
    my UUID $uuid = UUID.new;

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
        :$uuid,
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
    my Silo $silo = ::($<silo>.uc);

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
    # asset symbol
    my Str $asset_symbol;
    $asset_symbol = $<asset_symbol>.Str if $<asset_symbol>;

    # asset code
    my AssetCode $asset_code = $<asset_code>.Str;

    # asset quantity
    my Quantity $asset_quantity = Rat($<asset_quantity>.abs);

    # make exchange rate
    make Nightscape::Entry::Posting::Amount::XE.new(
        :$asset_symbol,
        :$asset_code,
        :$asset_quantity
    );
}

method amount($/)
{
    # asset symbol
    my Str $asset_symbol;
    $asset_symbol = $<asset_symbol>.Str if $<asset_symbol>;

    # asset code
    my AssetCode $asset_code = $<asset_code>.Str;

    # asset quantity
    my Quantity $asset_quantity = Rat($<asset_quantity>.abs);

    # minus sign
    my Str $minus_sign;
    $minus_sign = $<minus_sign>.Str if $<minus_sign>;

    # exchange rate
    my Nightscape::Entry::Posting::Amount::XE $exchange_rate =
        $<exchange_rate>».made.pairs[0].value // Nil;

    # make amount
    make Nightscape::Entry::Posting::Amount.new(
        :$asset_code,
        :$asset_quantity,
        :$asset_symbol,
        :$minus_sign,
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

    # dec / inc
    my DecInc $decinc = Nightscape::Types.mkdecinc: $amount.minus_sign.Bool;

    # make posting
    make Nightscape::Entry::Posting.new(
        :$account,
        :$amount,
        :$decinc
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

method include($/)
{
    # transaction journal to include
    my Str $filename;
    $filename = try {substr($<filename>, 1, *-1).trim} if $<filename>;

    # append .transactions extension to filename
    $filename ~= ".transactions" if $filename;

    # does include directive's transaction journal exist?
    if $filename && $filename.IO.e
    {
        # schedule included transaction journal for parsing
        use Nightscape::Parser::Include;
        make Nightscape::Parser::Include.new(:$filename);
    }
    else
    {
        # exit with an error
        die qq:to/EOF/;
        Sorry, could not locate transaction journal to include at

            「$filename」
        EOF
    }
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
    elsif $<include>
    {
        # included transaction journal
        make $<include>».made.list[0];
    }
}

method TOP($/)
{
    make $<journal>».made;
}

# vim: ft=perl6
