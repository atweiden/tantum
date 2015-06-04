use v6;
use Nightscape::Entry::Header;
use Nightscape::Entry::Posting;
unit class Nightscape::Entry;

has Nightscape::Entry::Header $.header;
has Nightscape::Entry::Posting @.postings;
has Str @.posting_comments;

# check if entry is balanced
method is_balanced(Nightscape::Config $conf) returns Bool
{
    use Nightscape::Types;

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
    my Date $date = self.header.date;

    # entry id
    my Int $id = self.header.id;

    # adjust running total for each posting in entry
    for self.postings -> $posting
    {
        # get value of posting in entity base currency
        my Quantity $posting_value = $posting.getvalue(
            $conf,
            $date,
            $id
        );

        # is posting denominated in asset other than entity's base
        # currency?
        my AssetCode $posting_entity_base_currency =
            $conf.get_base_currency($posting.account.entity);
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
                my Int $id = self.header.id;
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

# vim: ft=perl6
