use v6;
use Nightscape::Entry::Header;
use Nightscape::Entry::Posting;
use Nightscape::Types;
unit class Nightscape::Entry;

has Nightscape::Entry::Header $.header;
has Nightscape::Entry::Posting @.postings;
has Str @.posting_comments;

# check if entry is balanced
method is_balanced() returns Bool
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
    my Date $date = $!header.date;

    # entry id
    my Int $id = $!header.id;

    # adjust running total for each posting in entry
    for @!postings -> $posting
    {
        # get value of posting in entity base currency
        my Quantity $posting_value = $posting.get_value(:$date, :$id);

        # is posting denominated in asset other than entity's base
        # currency?
        my AssetCode $posting_entity_base_currency =
            $GLOBAL::conf.resolve_base_currency($posting.account.entity);
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
        my Int $multiplier = %multiplier{$silo};

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
        for %xe_verify.kv -> $asset_code, @exchange_rates
        {
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
    Nightscape::Entry::Posting :@postings = @!postings
) returns Array[AssetCode]
{
    my AssetCode @asset_codes;
    for @postings -> $posting
    {
        push @asset_codes, $_ for $posting.amount.asset_code;
    }
    my AssetCode @asset_codes_unique = @asset_codes.unique;
}

# list postings from entries
multi method ls_postings(
    Nightscape::Entry :@entries!
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @postings;
    for @entries -> $entry
    {
        push @postings, $_ for $entry.postings;
    }
    @postings;
}

# filter postings
multi method ls_postings(
    Nightscape::Entry::Posting :@postings!,
    Regex :$asset_code,
    Silo :$silo
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @p = @postings;
    @p = self._ls_postings(:postings(@p), :$asset_code) if defined $asset_code;
    @p = self._ls_postings(:postings(@p), :$silo) if defined $silo;
    @p;
}

# list postings by asset code
multi method _ls_postings(
    Nightscape::Entry::Posting :@postings!,
    Regex :$asset_code!
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @p = @postings.grep({
        .amount.asset_code ~~ $asset_code
    });
}

# list postings by silo
multi method _ls_postings(
    Nightscape::Entry::Posting :@postings!,
    Silo :$silo!
) returns Array[Nightscape::Entry::Posting]
{
    my Nightscape::Entry::Posting @p = @postings.grep({
        .account.silo ~~ $silo
    });
}

# vim: ft=perl6
