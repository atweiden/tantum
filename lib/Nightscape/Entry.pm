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
        Nightscape::Types.mksilo("ASSETS") => 1,
        Nightscape::Types.mksilo("EXPENSES") => 1,
        Nightscape::Types.mksilo("INCOME") => -1,
        Nightscape::Types.mksilo("LIABILITIES") => -1,
        Nightscape::Types.mksilo("EQUITY") => -1;

    # running total
    my Rat $total;

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
