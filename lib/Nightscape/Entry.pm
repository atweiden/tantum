use v6;
use Nightscape::Entry::Header;
use Nightscape::Entry::Posting;
use Nightscape::Types;
unit class Nightscape::Entry;

has EntryID $.id is required;
has Nightscape::Entry::Header $.header is required;
has Nightscape::Entry::Posting @.postings is required;

# check if entry is balanced
method is-balanced() returns Bool:D
{
    # Assets + Expenses = Income + Liabilities + Equity
    my Int %multiplier{Silo} =
        ::(ASSETS) => 1,
        ::(EXPENSES) => 1,
        ::(INCOME) => -1,
        ::(LIABILITIES) => -1,
        ::(EQUITY) => -1;

    # running total
    my FatRat $total;

    # exchange rate consistency verification
    my Array[Quantity] %xe-verify{AssetCode};

    # entry date
    my DateTime $date = $.header.date;

    # adjust running total for each posting in entry
    # keep tally of exchange rates per asset code seen
    for @.postings -> $posting
    {
        # get value of posting in entity base currency
        my Quantity $posting-value = $posting.get-value(:$date);

        # is posting denominated in asset other than entity's base
        # currency?
        my AssetCode $posting-entity-base-currency =
            $GLOBAL::CONF.resolve-base-currency($posting.account.entity);
        if $posting.amount.asset-code !eq $posting-entity-base-currency
        {
            # store posting exchange rate for comparison with other
            # postings affecting the same asset
            push %xe-verify{$posting.amount.asset-code},
                $posting.amount.exchange-rate.asset-quantity;
        }

        # get posting silo
        my Silo $silo = $posting.account.silo;

        # get posting decinc
        my DecInc $decinc = $posting.decinc;

        # get multiplier
        my Int $multiplier = %multiplier{::($silo)};

        # adjust running total
        if $decinc
        {
            # increase running total
            $total += $posting-value * $multiplier;
        }
        else
        {
            # decrease running total
            $total -= $posting-value * $multiplier;
        }
    }

    # exchange rate mismatch detection
    #
    # if exchange rate does not remain consistent for a given asset
    # within the span of one entry, exit with an error
    if %xe-verify
    {
        # for each asset code, process list of exchange rates seen
        for %xe-verify.kv -> $asset-code, @exchange-rates
        {
            # was there more than one unique exchange rate seen?
            unless @exchange-rates.unique.elems == 1
            {
                # error: exchange rate mismatch detected
                say qq:to/EOF/;
                Sorry, exchange rate for asset 「$asset-code」 does
                not remain consistent in entry id 「{$.id.canonical}」.

                To debug, verify transaction journal entry contains
                consistent exchange rate. If exchange rate sourced
                from config, check that configured exchange rate is
                correct.
                EOF
                die X::Nightscape::Entry::XEMismatch.new(:entry-id($.id));
            }
        }
    }

    # does the entry balance?
    if $total != 0
    {
        # TODO: make error margin configurable
        if $total.abs < 0.01
        {
            True;
        }
        else
        {
            False;
        }
    }
    else
    {
        True;
    }
}

# list unique asset codes in postings
method ls-asset-codes(
    Nightscape::Entry::Posting:D :@postings is readonly = @.postings
) returns Array[AssetCode:D]
{
    my AssetCode:D @asset-codes;
    for @postings -> $posting
    {
        push @asset-codes, $_ for $posting.amount.asset-code;
    }
    @asset-codes .= unique;
}

# list postings from entries
multi method ls-postings(
    Nightscape::Entry:D :@entries! is readonly
) returns Array[Nightscape::Entry::Posting:D]
{
    my Nightscape::Entry::Posting:D @postings;
    for @entries -> $entry
    {
        push @postings, $_ for $entry.postings;
    }
    @postings;
}

# filter postings
multi method ls-postings(
    Nightscape::Entry::Posting:D :@postings is readonly = @.postings,
    Regex :$asset-code,
    Silo :$silo,
    PostingID :$posting-id
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @p = @postings;
    @p = self._ls-postings(:postings(@p), :$asset-code) if defined $asset-code;
    @p = self._ls-postings(:postings(@p), :$silo) if defined $silo;
    @p = self._ls-postings(:postings(@p), :$posting-id) if $posting-id;
    @p;
}

# list postings by asset code
multi method _ls-postings(
    Nightscape::Entry::Posting:D :@postings! is readonly,
    Regex:D :$asset-code!
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @p = @postings.grep({
        .amount.asset-code ~~ $asset-code
    });
}

# list postings by silo
multi method _ls-postings(
    Nightscape::Entry::Posting:D :@postings! is readonly,
    Silo:D :$silo!
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @p = @postings.grep({
        .account.silo ~~ $silo
    });
}

# list postings by PostingID
multi method _ls-postings(
    Nightscape::Entry::Posting:D :@postings! is readonly,
    PostingID:D :$posting-id!
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @p = @postings.grep({ .id == $posting-id });
}

# vim: ft=perl6
