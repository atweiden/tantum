use v6;
use Nightscape::Config;
use Nightscape::Entry::Posting::Account;
use Nightscape::Entry::Posting::Amount;
use Nightscape::Types;
unit class Nightscape::Entry::Posting;

has Nightscape::Entry::Posting::Account $.account;
has Nightscape::Entry::Posting::Amount $.amount;
has DecInc $.decinc;

# get posting value in entity's base currency
#
# if posting commodity code equivalent to entity's base currency, return
# commodity_quantity from posting
#
# if posting commodity code differs from entity's base currency, seek
# exchange rate, first in transaction journal, then in config file
#
# if exchange rate found in config file, has side effect of instantiating
# XE class based on price data from config file
#
# if suitable exchange rate not found anywhere, exit with an error
method getvalue(
    Nightscape::Config $conf,
    Date $date,
    Int $id
) returns Quantity
{
    # account
    my Nightscape::Entry::Posting::Account $account = self.account;

    # amount
    my Nightscape::Entry::Posting::Amount $amount = self.amount;

    # entity
    my VarName $posting_entity = $account.entity;

    # entity's base currency
    my CommodityCode $posting_entity_base_currency =
        $conf.get_base_currency($posting_entity);

    # posting commodity code
    my CommodityCode $posting_commodity_code = $amount.commodity_code;

    # posting commodity quantity
    my Quantity $posting_commodity_quantity = $amount.commodity_quantity;

    # posting value
    my Quantity $posting_value;

    # search for exchange rate?
    if $posting_commodity_code !eq $posting_entity_base_currency
    {
        use Nightscape::Entry::Posting::Amount::XE;

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
                number $id.
                EOF
                die $help_text_faulty_exchange_rate.trim;
            }
        }
        # is an exchange rate given in config?
        elsif my Price $price = $conf.getprice(
            aux => $posting_commodity_code,
            base => $posting_entity_base_currency,
            date => $date
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

                    date: 「$date」
                    entity: 「$posting_entity」
                    base-currency: 「$posting_entity_base_currency」
                    currency code given in journal: 「$posting_commodity_code」

            To debug, confirm that the data for price pair:

                「$posting_entity_base_currency/$posting_commodity_code」

            on 「$date」 was entered accurately for entry number
            $id. Verify that the entity of entry number
            $id has been configured with the correct
            base-currency.
            EOF
            die $help_text_faulty_exchange_rate_in_config_file.trim;
        }

        $posting_value;
    }
    else
    {
        $posting_commodity_quantity;
    }
}

# vim: ft=perl6
