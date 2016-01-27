use v6;
use Nightscape::Entry;
use Nightscape::Types;
unit class Nightscape::Import;

method gen-datetime($dt) returns DateTime:D
{
    my DateTime:D $date = $dt;
}

method gen-varname(Str:D $vn) returns VarName:D
{
    if $vn ~~ / (\S+) { my VarName:D $v = "$0"; make $v; } /
    {
        my VarName:D $varname = $/.made;
    }
}

method gen-varnames(@vns) returns Array[VarName:D]
{
    my VarName:D @varnames;
    for @vns -> $vn
    {
        my VarName:D $varname = self.gen-varname($vn);
        push @varnames, $varname;
    }
    @varnames;
}

method gen-entry-header(%header-container) returns Nightscape::Entry::Header:D
{
    my %h;

    %h<date> = self.gen-datetime(%header-container<date>);

    my Str $description = %header-container<description>;
    %h<description> = $description if $description;

    my Int $important = %header-container<important>;
    %h<important> = $important.defined ?? $important !! 0;

    if %header-container<tags>
    {
        my VarName:D @tags = self.gen-varnames(%header-container<tags>);
        %h<tags> := @tags;
    }

    my Nightscape::Entry::Header $header .= new(|%h);
}

method gen-entry-id(%entry-id-container) returns EntryID:D
{
    my Int:D $number = %entry-id-container<number>;
    my Str:D $text = %entry-id-container<text>;
    my xxHash:D $xxhash = %entry-id-container<xxhash>;
    my EntryID $entry-id .= new(:$number, :$text, :$xxhash);
}

method gen-posting-id(%posting-id-container) returns PostingID:D
{
    my EntryID:D $entry-id = self.gen-entry-id(%posting-id-container<entry-id>);
    my Int:D $number = %posting-id-container<number>;
    my Str:D $text = %posting-id-container<text>;
    my xxHash:D $xxhash = %posting-id-container<xxhash>;
    my PostingID $posting-id .= new(:$entry-id, :$number, :$text, :$xxhash);
}

method gen-entry-posting-account(
    %posting-account-container
) returns Nightscape::Entry::Posting::Account:D
{
    my %h;

    # :: Silo is enum
    my Silo:D $silo = ::(%posting-account-container<silo>);
    %h<silo> = $silo;

    my VarName:D $entity = %posting-account-container<entity>;
    %h<entity> = $entity;

    if %posting-account-container<subaccount>
    {
        my Str:D @subacct = |%posting-account-container<subaccount>;
        my VarName:D @subaccount = self.gen-varnames(@subacct);
        %h<subaccount> := @subaccount;
    }

    my Nightscape::Entry::Posting::Account $account .= new(|%h);
}

method gen-entry-posting-amount-xe(
    %posting-amount-xe-container
) returns Nightscape::Entry::Posting::Amount::XE:D
{
    my %h;

    my AssetCode:D $asset-code = %posting-amount-xe-container<asset-code>;
    %h<asset-code> = $asset-code;

    my Quantity:D $asset-quantity =
        FatRat(%posting-amount-xe-container<asset-quantity>);
    %h<asset-quantity> = $asset-quantity;

    my Str $asset-symbol = %posting-amount-xe-container<asset-symbol>;
    %h<asset-symbol> = $asset-symbol if $asset-symbol;

    my Nightscape::Entry::Posting::Amount::XE $exchange-rate .= new(|%h);
}

method gen-entry-posting-amount(
    %posting-amount-container
) returns Nightscape::Entry::Posting::Amount:D
{
    my %h;

    my AssetCode:D $asset-code = %posting-amount-container<asset-code>;
    %h<asset-code> = $asset-code;

    my Quantity:D $asset-quantity =
        FatRat(%posting-amount-container<asset-quantity>);
    %h<asset-quantity> = $asset-quantity;

    my Str $asset-symbol = %posting-amount-container<asset-symbol>;
    %h<asset-symbol> = $asset-symbol if $asset-symbol;

    my Str $plus-or-minus = %posting-amount-container<plus-or-minus>;
    %h<plus-or-minus> = $plus-or-minus if $plus-or-minus;

    if %posting-amount-container<exchange-rate>
    {
        my Nightscape::Entry::Posting::Amount::XE:D $exchange-rate =
            self.gen-entry-posting-amount-xe(
                %posting-amount-container<exchange-rate>
            );
        %h<exchange-rate> = $exchange-rate;
    }

    my Nightscape::Entry::Posting::Amount $amount .= new(|%h);
}

method gen-entry-posting(%posting-container) returns Nightscape::Entry::Posting:D
{
    my PostingID:D $id = self.gen-posting-id(%posting-container<id>);

    my Nightscape::Entry::Posting::Account:D $account =
        self.gen-entry-posting-account(%posting-container<account>);

    my Nightscape::Entry::Posting::Amount:D $amount =
        self.gen-entry-posting-amount(%posting-container<amount>);

    # :: DecInc is enum
    my DecInc:D $decinc = ::(%posting-container<decinc>);

    my Nightscape::Entry::Posting $posting .= new(
        :$id,
        :$account,
        :$amount,
        :$decinc
    );
}

method gen-entry-postings(
    @posting-containers
) returns Array #Array[Nightscape::Entry::Posting:D]
{
    my Nightscape::Entry::Posting:D @postings =
        self.gen-entry-posting($_) for @posting-containers;
    @postings;
}

method gen-entry(%entry-container) returns Nightscape::Entry:D
{
    my Nightscape::Entry::Header:D $header =
        self.gen-entry-header(%entry-container<header>);

    my EntryID:D $id = self.gen-entry-id(%entry-container<id>);

    my Nightscape::Entry::Posting:D @postings =
        self.gen-entry-postings(%entry-container<postings>);

    my Nightscape::Entry $entry .= new(:$header, :$id, :@postings);
}

method gen-entries(@entry-containers) returns Array[Nightscape::Entry:D]
{
    my Nightscape::Entry:D @entries;
    push @entries, self.gen-entry($_) for @entry-containers;
    @entries;
}

# vim: ft=perl6
