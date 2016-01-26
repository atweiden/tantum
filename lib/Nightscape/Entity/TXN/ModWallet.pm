use v6;
use Nightscape::Types;
unit class Nightscape::Entity::TXN::ModWallet;

# parent entity
has VarName $.entity is required;

# causal EntryID
has EntryID $.entry-id is required;

# causal PostingID
has PostingID $.posting-id is required;

# account
has Silo $.silo is required;
has VarName @.subwallet;

# amount
has AssetCode $.asset-code is required;
has DecInc $.decinc is required;
has Quantity $.quantity is required;

# xe
has AssetCode $.xe-asset-code;
has Quantity $.xe-asset-quantity;

# get AcctName
method get-acct-name() returns AcctName:D
{
    my VarName @path = ~$.silo, |@.subwallet.grep({.defined});
    my AcctName $acct-name = @path.join(':');
}

# get value of TXN::ModWallet in entity base currency
method get-value() returns Quantity:D
{
    # TXN::ModWallet value in entity base currency
    my Quantity $value;

    # entity base currency
    my AssetCode $entity-base-currency = $GLOBAL::CONF.resolve-base-currency(
        $.entity
    );

    # is it necessary to search for an exchange rate?
    if $.asset-code !eq $entity-base-currency
    {
        # is an exchange rate given in the TXN?
        if $.xe-asset-quantity
        {
            # try calculating value in base currency
            if $.xe-asset-code eq $entity-base-currency
            {
                $value = $.quantity * $.xe-asset-quantity;
            }
            else
            {
                die "Sorry, TXN::ModWallet xe-asset-code did not match
                     entity base currency asset code";
            }
        }
        else
        {
            die "Sorry, missing xe-asset-quantity in TXN::ModWallet of
                 aux asset";
        }
    }
    else
    {
        # use main asset code
        $value = $.quantity;
    }

    $value;
}

# deconstruct value of TXN::ModWallet into ٍ± FatRat
method get-raw-value() returns FatRat:D
{
    # get DecInc
    my DecInc $decinc = $.decinc;

    # get value
    my Quantity $value = self.get-value;

    # convert to raw FatRat value
    my FatRat $raw-value = $decinc ~~ INC ?? $value !! -$value;
}

# vim: ft=perl6
