use v6;
use Nightscape::Config;
use Nightscape::Entry;
use Nightscape::Entry::Header;
use Nightscape::Entry::Posting;
use Nightscape::Entry::Posting::Account;
use Nightscape::Entry::Posting::Amount;
use Nightscape::Entry::Posting::Amount::XE;
use Nightscape::Types;
class Nightscape::Parser::Actions;

has Nightscape::Config $.conf;

my Int $entry_number = 0;
my Date $entry_date;

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
    $entry_date = $<iso_date>».made.pairs[0].value;

    # entry description
    my Str $description = try {substr($<description>, 1, *-1).trim} // Nil;

    # entry importance
    my Int $important = [+] $<important>».made // 0;

    # entry tags
    my VarName @tags = $<tag>».made // Nil;

    # entry eol comment
    my Str $eol_comment = try {substr($<eol_comment>, 1, *-0).trim} // Nil;

    # make entry header
    make Nightscape::Entry::Header.new(
        id => $id,
        date => $entry_date,
        description => $description,
        important => $important,
        tags => @tags,
        eol_comment => $eol_comment
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
        silo => $silo,
        entity => $entity,
        subaccount => @subaccount
    );
}

method exchange_rate($/)
{
    # commodity symbol
    my Str $commodity_symbol = $<commodity_symbol>.Str // Nil;

    # commodity code
    my CommodityCode $commodity_code = $<commodity_code>.Str;

    # commodity quantity
    my Quantity $commodity_quantity = $<commodity_quantity>.abs;

    # make exchange rate
    make Nightscape::Entry::Posting::Amount::XE.new(
        commodity_symbol => $commodity_symbol,
        commodity_code => $commodity_code,
        commodity_quantity => $commodity_quantity
    );
}

method amount($/)
{
    # commodity symbol
    my Str $commodity_symbol = $<commodity_symbol>.Str // Nil;

    # commodity code
    my CommodityCode $commodity_code = $<commodity_code>.Str;

    # commodity quantity
    my Quantity $commodity_quantity = $<commodity_quantity>.abs;

    # commodity minus
    my Str $commodity_minus = $<commodity_minus>.Str;

    # exchange rate
    my Nightscape::Entry::Posting::Amount::XE $exchange_rate =
        $<exchange_rate>».made.pairs[0].value // Nil;

    # make amount
    make Nightscape::Entry::Posting::Amount.new(
        commodity_code => $commodity_code,
        commodity_quantity => $commodity_quantity,
        commodity_symbol => $commodity_symbol,
        commodity_minus => $commodity_minus,
        exchange_rate => $exchange_rate
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

    # entity
    my VarName $posting_entity = $account.entity;

    # entity's base currency
    my CommodityCode $posting_entity_base_currency =
        self.conf.get_base_currency($posting_entity);

    # posting commodity code
    my CommodityCode $posting_commodity_code = $amount.commodity_code;

    # posting commodity quantity
    my Quantity $posting_commodity_quantity = $amount.commodity_quantity;

    # posting value
    my Quantity $posting_value;

    # search for exchange rate?
    if $posting_commodity_code !eq $posting_entity_base_currency
    {
        # is an exchange rate given in the transaction journal?
        if my Nightscape::Entry::Posting::Amount::XE $exchange_rate =
            $amount.exchange_rate
        {
            # try calculating posting value in base currency
            if $exchange_rate.commodity_code eq $posting_entity_base_currency
            {
                $posting_value =
                    $posting_commodity_quantity
                        * $exchange_rate.commodity_quantity;
            }
            else
            {
                # error: suitable exchange rate not found
                my CommodityCode $xecc = $exchange_rate.commodity_code;
                my Str $help_text_faulty_exchange_rate = qq:to/EOF/;
                Sorry, exchange rate detected in transaction journal
                doesn't match the parsed entity's base-currency:

                    entity: 「$posting_entity」
                    base-currency: 「$posting_entity_base_currency」
                    exchange rate currency code given in journal: 「$xecc」

                To debug, verify that the entity has been configured with
                the correct base-currency. Then verify the transaction
                journal gives a matching base-currency code for entry
                number $entry_number.
                EOF
                die $help_text_faulty_exchange_rate.trim;
            }
        }
        # is an exchange rate given in config?
        elsif my Price $price = self.conf.getprice(
            aux => $posting_commodity_code,
            base => $posting_entity_base_currency,
            date => $entry_date
        )
        {
            # assign exchange rate because one was not included in the journal
            $amount.exchange_rate =
                Nightscape::Entry::Posting::Amount::XE.new(
                    commodity_code => $posting_entity_base_currency,
                    commodity_quantity => $price
                );

            # try calculating posting value in base currency
            $posting_value = $posting_commodity_quantity * $price;
        }
        else
        {
            # error: suitable exchange rate not found
            my Str $help_text_faulty_exchange_rate_in_config_file = qq:to/EOF/;
            Sorry, exchange rate missing for posting in transaction
            journal.

            The transaction journal does not offer an exchange rate
            with @ syntax, and the config file does not offer an
            exchange rate for the posting entity's base-currency on
            the date of the posting:

                    date: 「$entry_date」
                    entity: 「$posting_entity」
                    base-currency: 「$posting_entity_base_currency」
                    currency code given in journal: 「$posting_commodity_code」

            To debug, confirm that the data for price pair:

                「$posting_entity_base_currency/$posting_commodity_code」

            on 「$entry_date」 was entered accurately for entry number
            $entry_number. Verify that the entity of entry number
            $entry_number has been configured with the correct
            base-currency.
            EOF
            die $help_text_faulty_exchange_rate_in_config_file.trim;
        }
    }

    # make posting
    make Nightscape::Entry::Posting.new(
        account => $account,
        amount => $amount,
        drcr => $drcr
    );
}

method entry($/)
{
    # header
    my Nightscape::Entry::Header $header =
        $<header>».made.pairs[0].value;

    # postings
    my Nightscape::Entry::Posting @postings =
        @<posting>».made.list.values;

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
        header => $header,
        postings => @postings,
        posting_comments => @posting_comments
    );
    $entry_number++;
}

method journal($/)
{
    # blank line
    my Bool $is_blank_line = $<blank_line>.Bool;

    # comment line
    my Str $comment_line =
        $<comment_line>.Str.map({ try {substr($_, 1, *-0).trim} }).pairs[0].value // Nil;

    if $<entry>
    {
        # journal entry
        my %entry = $<entry>».made;
        my Nightscape::Entry::Header $header = %entry<header>;
        my Nightscape::Entry::Posting @postings = %entry<postings>.list;
        my Str @posting_comments = %entry<posting_comments>.list;

        # make entry
        make Nightscape::Entry.new(
            header => $header,
            postings => @postings,
            posting_comments => @posting_comments
        );
    }
}

method TOP($/)
{
    make $<journal>».made;
}

# vim: ft=perl6
