use v6;
use Nightscape::Entry;
use Nightscape::Types;
unit class Nightscape::Import;

sub gen_entry_header(%header_container) returns Nightscape::Entry::Header:D
{
    my %h;

    # parse stringified DateTime
    {
        my Str:D $header_date_container = %header_container<date>;
        use TXN::Parser::Actions;
        use TXN::Parser::Grammar;
        my TXN::Parser::Actions $actions .= new;
        my DateTime:D $date = TXN::Parser::Grammar.parse(
            $header_date_container,
            :$actions,
            :rule<date>
        ).made;
        %h<date> = $date;
    }

    my Str $description = %header_container<description>;
    %h<description> = $description if $description;

    my Int $important = %header_container<important>;
    %h<important> = $important.defined ?? $important !! 0;

    if %header_container<tags>
    {
        my VarName:D @tags;
        push @tags, $_ for %header_container<tags>.Array;
        %h<tags> = @tags;
    }

    my Nightscape::Entry::Header $header .= new(|%h);
}

sub gen_entry_id(%entry_id_container) returns EntryID:D
{
    my Int:D $number = %entry_id_container<number>;
    my Str:D $text = %entry_id_container<text>;
    my xxHash:D $xxhash = %entry_id_container<xxhash>;
    my EntryID $entry_id .= new(:$number, :$text, :$xxhash);
}

sub gen_posting_id(%posting_id_container) returns PostingID:D
{
    my EntryID:D $entry_id = gen_entry_id(%posting_id_container<entry_id>);
    my Int:D $number = %posting_id_container<number>;
    my Str:D $text = %posting_id_container<text>;
    my xxHash:D $xxhash = %posting_id_container<xxhash>;
    my PostingID $posting_id .= new(:$entry_id, :$number, :$text, :$xxhash);
}

sub gen_entry_posting_account(
    %posting_account_container
) returns Nightscape::Entry::Posting::Account:D
{
    my %h;

    # :: Silo is enum
    my Silo:D $silo = ::(%posting_account_container<silo>);
    %h<silo> = $silo;

    my VarName:D $entity = %posting_account_container<entity>;
    %h<entity> = $entity;

    if %posting_account_container<subaccount>
    {
        my VarName:D @subaccount;
        push @subaccount, $_ for |%posting_account_container<subaccount>;
        %h<subaccount> = @subaccount;
    }

    my Nightscape::Entry::Posting::Account $account .= new(|%h);
}

sub gen_entry_posting_amount_xe(
    %posting_amount_xe_container
) returns Nightscape::Entry::Posting::Amount::XE:D
{
    my %h;

    my AssetCode:D $asset_code = %posting_amount_xe_container<asset_code>;
    %h<asset_code> = $asset_code;

    my Quantity:D $asset_quantity =
        FatRat(%posting_amount_xe_container<asset_quantity>);
    %h<asset_quantity> = $asset_quantity;

    my Str $asset_symbol = %posting_amount_xe_container<asset_symbol>;
    %h<asset_symbol> = $asset_symbol if $asset_symbol;

    my Nightscape::Entry::Posting::Amount::XE $exchange_rate .= new(|%h);
}

sub gen_entry_posting_amount(
    %posting_amount_container
) returns Nightscape::Entry::Posting::Amount:D
{
    my %h;

    my AssetCode:D $asset_code = %posting_amount_container<asset_code>;
    %h<asset_code> = $asset_code;

    my Quantity:D $asset_quantity =
        FatRat(%posting_amount_container<asset_quantity>);
    %h<asset_quantity> = $asset_quantity;

    my Str $asset_symbol = %posting_amount_container<asset_symbol>;
    %h<asset_symbol> = $asset_symbol if $asset_symbol;

    my Str $plus_or_minus = %posting_amount_container<plus_or_minus>;
    %h<plus_or_minus> = $plus_or_minus if $plus_or_minus;

    if %posting_amount_container<exchange_rate>
    {
        my Nightscape::Entry::Posting::Amount::XE:D $exchange_rate =
            gen_entry_posting_amount_xe(
                %posting_amount_container<exchange_rate>
            );
        %h<exchange_rate> = $exchange_rate;
    }

    my Nightscape::Entry::Posting::Amount $amount .= new(|%h);
}

sub gen_entry_posting(%posting_container) returns Nightscape::Entry::Posting:D
{
    my PostingID:D $id = gen_posting_id(%posting_container<id>);

    my Nightscape::Entry::Posting::Account:D $account =
        gen_entry_posting_account(%posting_container<account>);

    my Nightscape::Entry::Posting::Amount:D $amount =
        gen_entry_posting_amount(%posting_container<amount>);

    # :: DecInc is enum
    my DecInc:D $decinc = ::(%posting_container<decinc>);

    my Nightscape::Entry::Posting $posting .= new(
        :$id,
        :$account,
        :$amount,
        :$decinc
    );
}

sub gen_entry_postings(
    @posting_containers
) returns Array[Nightscape::Entry::Posting:D]
{
    my Nightscape::Entry::Posting:D @postings =
        gen_entry_posting($_) for @posting_containers;
    @postings;
}

sub gen_entry(%entry_container) returns Nightscape::Entry:D
{
    my Nightscape::Entry::Header:D $header =
        gen_entry_header(%entry_container<header>);

    my EntryID:D $id = gen_entry_id(%entry_container<id>);

    my Nightscape::Entry::Posting:D @postings =
        gen_entry_postings(%entry_container<postings>);

    my Nightscape::Entry $entry .= new(:$header, :$id, :@postings);
}

sub gen_entries(@entry_containers) returns Array[Nightscape::Entry:D]
{
    my Nightscape::Entry:D @entries;
    push @entries, gen_entry($_) for @entry_containers;
    @entries;
}

method entries(Str:D $json) returns Array[Nightscape::Entry:D]
{
    use JSON::Tiny;
    my Nightscape::Entry:D @entries = gen_entries(from-json($json).Array);
    @entries;
}

# vim: ft=perl6
