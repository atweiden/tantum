use v6;
use Nightscape::Entry::Header;
use Nightscape::Entry::Posting;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entry;

has Nightscape::Entry::Header $.header;
has Nightscape::Entry::Posting @.postings;
has Str @.posting_comments;

# check if entry is balanced
method is_balanced() returns Bool:D
{
    # Assets + Expenses = Income + Liabilities + Equity
    my Int %multiplier{Silo} =
        ::(ASSETS) => 1,
        ::(EXPENSES) => 1,
        ::(INCOME) => -1,
        ::(LIABILITIES) => -1,
        ::(EQUITY) => -1;

    # running total
    my Rat $total;

    # exchange rate consistency verification
    my Array[Quantity] %xe_verify{AssetCode};

    # entry date
    my Date $date = $.header.date;

    # entry id
    my Int $id = $.header.id;

    # adjust running total for each posting in entry
    # keep tally of exchange rates per asset code seen
    for @.postings -> $posting
    {
        # get value of posting in entity base currency
        my Quantity $posting_value = $posting.get_value(:$date, :$id);

        # is posting denominated in asset other than entity's base
        # currency?
        my AssetCode $posting_entity_base_currency =
            $GLOBAL::CONF.resolve_base_currency($posting.account.entity);
        if $posting.amount.asset_code !eq $posting_entity_base_currency
        {
            # store posting exchange rate for comparison with other
            # postings affecting the same asset
            push %xe_verify{$posting.amount.asset_code},
                $posting.amount.exchange_rate.asset_quantity;
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
            $total += $posting_value * $multiplier;
        }
        else
        {
            # decrease running total
            $total -= $posting_value * $multiplier;
        }
    }

    # exchange rate mismatch detection
    #
    # if exchange rate does not remain consistent for a given asset
    # within the span of one entry, exit with an error
    if %xe_verify
    {
        # for each asset code, process list of exchange rates seen
        for %xe_verify.kv -> $asset_code, @exchange_rates
        {
            # was there more than one unique exchange rate seen?
            unless @exchange_rates.unique.elems == 1
            {
                # error: exchange rate mismatch detected
                die qq:to/EOF/;
                Sorry, exchange rate for asset 「$asset_code」 does
                not remain consistent in entry id 「$id」.

                To debug, verify transaction journal entry contains
                consistent exchange rate. If exchange rate sourced
                from config, check that configured exchange rate is
                correct.
                EOF
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
method ls_asset_codes(
    Nightscape::Entry::Posting:D :@postings is readonly = @.postings
) returns Array[AssetCode:D]
{
    my AssetCode:D @asset_codes;
    for @postings -> $posting
    {
        push @asset_codes, $_ for $posting.amount.asset_code;
    }
    @asset_codes .= unique;
}

# list postings from entries
multi method ls_postings(
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
multi method ls_postings(
    Nightscape::Entry::Posting:D :@postings is readonly = @.postings,
    Regex :$asset_code,
    Silo :$silo,
    UUID :$posting_uuid
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @p = @postings;
    @p = self._ls_postings(:postings(@p), :$asset_code) if defined $asset_code;
    @p = self._ls_postings(:postings(@p), :$silo) if defined $silo;
    @p = self._ls_postings(:postings(@p), :$posting_uuid) if $posting_uuid;
    @p;
}

# list postings by asset code
multi method _ls_postings(
    Nightscape::Entry::Posting:D :@postings! is readonly,
    Regex:D :$asset_code!
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @p = @postings.grep({
        .amount.asset_code ~~ $asset_code
    });
}

# list postings by silo
multi method _ls_postings(
    Nightscape::Entry::Posting:D :@postings! is readonly,
    Silo:D :$silo!
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @p = @postings.grep({
        .account.silo ~~ $silo
    });
}

# list postings by uuid
multi method _ls_postings(
    Nightscape::Entry::Posting:D :@postings! is readonly,
    UUID:D :$posting_uuid!
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @p = @postings.grep({
        .posting_uuid ~~ $posting_uuid
    });
}

# vim: ft=perl6
