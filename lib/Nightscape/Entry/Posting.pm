use v6;
use Nightscape::Entry::Posting::Account;
use Nightscape::Entry::Posting::Amount;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entry::Posting;

has UUID $.entry_uuid;
has UUID $.posting_uuid;
has Nightscape::Entry::Posting::Account $.account;
has Nightscape::Entry::Posting::Amount $.amount;
has DecInc $.decinc;

# get posting value in entity's base currency
#
# if posting asset code equivalent to entity's base currency, return
# asset_quantity from posting
#
# if posting asset code differs from entity's base currency, seek
# exchange_rate, first in transaction journal, then in config file
#
# if exchange_rate found in config file, has side effect of instantiating
# XE class based on price data from config file
#
# if suitable exchange_rate not found anywhere, exit with an error
method get_value(Date :$date!, Int :$id!) returns Quantity
{
    # account
    my Nightscape::Entry::Posting::Account $account = $.account;

    # amount
    #
    # $! rw privs required because XE update in-place is possible if:
    # - an exchange rate is needed
    # - no exchange rate is given in the transaction journal
    # - an exchange rate is then found in config
    my Nightscape::Entry::Posting::Amount $amount = $!amount;

    # entity
    my VarName $posting_entity = $account.entity;

    # entity's base currency
    my AssetCode $posting_entity_base_currency =
        $GLOBAL::CONF.resolve_base_currency($posting_entity);

    # posting asset code
    my AssetCode $posting_asset_code = $amount.asset_code;

    # posting asset quantity
    my Quantity $posting_asset_quantity = $amount.asset_quantity;

    # posting value
    my Quantity $posting_value;

    # posting value must be able to resolve in terms of entity's base currency
    #
    # is it necessary to search for exchange rate?
    if $posting_asset_code !eq $posting_entity_base_currency
    {
        use Nightscape::Entry::Posting::Amount::XE;

        # is an exchange rate given in the transaction journal?
        if my Nightscape::Entry::Posting::Amount::XE $exchange_rate =
            $amount.exchange_rate
        {
            # try calculating posting value in base currency
            if $exchange_rate.asset_code eq $posting_entity_base_currency
            {
                $posting_value =
                    $posting_asset_quantity * $exchange_rate.asset_quantity;
            }
            else
            {
                # error: suitable exchange rate not found
                my AssetCode $xeac = $exchange_rate.asset_code;
                my Str $help_text_faulty_exchange_rate = qq:to/EOF/;
                Sorry, exchange rate detected in transaction journal
                doesn't match the parsed entity's base-currency:

                    entity: 「$posting_entity」
                    base-currency: 「$posting_entity_base_currency」
                    exchange rate currency code given in journal: 「$xeac」

                To debug, verify that the entity has been configured with
                the correct base-currency. Then verify the transaction
                journal gives a matching base-currency code for entry
                number $id.
                EOF
                die $help_text_faulty_exchange_rate.trim;
            }
        }
        # is an exchange rate given in config?
        elsif my Price $price = $GLOBAL::CONF.resolve_price(
            :aux($posting_asset_code),
            :base($posting_entity_base_currency),
            :$date,
            :entity_name($posting_entity)
        )
        {
            # assign exchange rate because one was not included in the journal
            $amount.mkxe(:$posting_entity_base_currency, :$price);

            # try calculating posting value in base currency
            $posting_value = $posting_asset_quantity * $price;
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
                    currency code given in journal: 「$posting_asset_code」

            To debug, confirm that the data for price pair:

                「$posting_entity_base_currency/$posting_asset_code」

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
        # posting entity's base currency matches posting's main asset code
        #
        # use posting's main asset code
        $posting_asset_quantity;
    }
}

# vim: ft=perl6
