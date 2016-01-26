use v6;
use Nightscape::Entry::Posting::Account;
use Nightscape::Entry::Posting::Amount;
use Nightscape::Types;
unit class Nightscape::Entry::Posting;

has PostingID $.id is required;
has Nightscape::Entry::Posting::Account $.account is required;
has Nightscape::Entry::Posting::Amount $.amount is required;
has DecInc $.decinc is required;

# get posting value in entity's base currency
#
# if posting asset code equivalent to entity's base currency, return
# asset-quantity from posting
#
# if posting asset code differs from entity's base currency, seek
# exchange-rate, first in transaction journal, then in config file
#
# if exchange-rate found in config file, has side effect of instantiating
# XE class based on price data from config file
#
# if suitable exchange-rate not found anywhere, exit with an error
method get-value(DateTime:D :$date!) returns Quantity:D
{
    # entity
    my VarName $posting-entity = $.account.entity;

    # entity's base currency
    my AssetCode $posting-entity-base-currency =
        $GLOBAL::CONF.resolve-base-currency($posting-entity);

    # posting asset code
    my AssetCode $posting-asset-code = $.amount.asset-code;

    # posting asset quantity
    my Quantity $posting-asset-quantity = $.amount.asset-quantity;

    # posting value
    my Quantity $posting-value;

    # posting value must be able to resolve in terms of entity's base currency
    #
    # is it necessary to search for exchange rate?
    if $posting-asset-code !eq $posting-entity-base-currency
    {
        # is an exchange rate given in the transaction journal?
        if my Nightscape::Entry::Posting::Amount::XE $exchange-rate =
            $.amount.exchange-rate
        {
            # try calculating posting value in base currency
            if $exchange-rate.asset-code eq $posting-entity-base-currency
            {
                $posting-value =
                    $posting-asset-quantity * $exchange-rate.asset-quantity;
            }
            else
            {
                # error: suitable exchange rate not found
                my AssetCode $xeac = $exchange-rate.asset-code;
                my Str $help-text-faulty-exchange-rate = qq:to/EOF/;
                Sorry, exchange rate detected in transaction journal
                posting id 「{$.id.canonical}」 doesn't match the
                parsed entity's base-currency:

                    entity: 「$posting-entity」
                    base-currency: 「$posting-entity-base-currency」
                    exchange rate currency code given in journal: 「$xeac」

                To debug, verify that the entity has been configured with
                the correct base-currency. Then verify the transaction
                journal gives a matching base-currency code.
                EOF
                say $help-text-faulty-exchange-rate.trim;
                die X::Nightscape::Posting::XEBad.new(:posting-id($.id));
            }
        }
        # is an exchange rate given in config?
        elsif my Price $price = $GLOBAL::CONF.resolve-price(
            :aux($posting-asset-code),
            :base($posting-entity-base-currency),
            :$date,
            :entity-name($posting-entity)
        )
        {
            # assign exchange rate because one was not included in the journal
            $!amount.mkxe(:$posting-entity-base-currency, :$price);

            # try calculating posting value in base currency
            $posting-value = $posting-asset-quantity * $price;
        }
        else
        {
            # error: suitable exchange rate not found
            my Str $help-text-faulty-exchange-rate-in-config-file = qq:to/EOF/;
            Sorry, exchange rate missing for posting in transaction
            journal.

            The transaction journal does not offer an exchange rate
            with @ syntax, and the config file does not offer an
            exchange rate for the posting entity's base-currency on
            the date of the posting:

                    date: 「$date」
                    entity: 「$posting-entity」
                    base-currency: 「$posting-entity-base-currency」
                    currency code given in journal: 「$posting-asset-code」

            To debug, confirm that the data for price pair:

                「$posting-entity-base-currency/$posting-asset-code」

            on 「$date」 was entered accurately.

            Verify that the entity of entry has been configured with
            the correct base-currency.
            EOF
            say $help-text-faulty-exchange-rate-in-config-file.trim;
            die X::Nightscape::Posting::XEMissing.new(:posting-id($.id));
        }

        $posting-value;
    }
    else
    {
        # posting entity's base currency matches posting's main asset code
        #
        # use posting's main asset code
        $posting-asset-quantity;
    }
}

# vim: ft=perl6
