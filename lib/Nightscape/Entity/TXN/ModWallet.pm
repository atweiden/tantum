use v6;
use Nightscape::Types;
unit class Nightscape::Entity::TXN::ModWallet;

# parent entity
has VarName $.entity;

# causal EntryID
has EntryID $.entry_id;

# causal PostingID
has PostingID $.posting_id;

# account
has Silo $.silo;
has VarName @.subwallet;

# amount
has AssetCode $.asset_code;
has DecInc $.decinc;
has Quantity $.quantity;

# xe
has AssetCode $.xe_asset_code;
has Quantity $.xe_asset_quantity;

# get AcctName
method get_acct_name() returns AcctName:D
{
    my VarName @path = ~$.silo, |@.subwallet.grep({.defined});
    my AcctName $acct_name = @path.join(':');
}

# get value of TXN::ModWallet in entity base currency
method get_value() returns Quantity:D
{
    # TXN::ModWallet value in entity base currency
    my Quantity $value;

    # entity base currency
    my AssetCode $entity_base_currency = $GLOBAL::CONF.resolve_base_currency(
        $.entity
    );

    # is it necessary to search for an exchange rate?
    if $.asset_code !eq $entity_base_currency
    {
        # is an exchange rate given in the TXN?
        if $.xe_asset_quantity
        {
            # try calculating value in base currency
            if $.xe_asset_code eq $entity_base_currency
            {
                $value = $.quantity * $.xe_asset_quantity;
            }
            else
            {
                die "Sorry, TXN::ModWallet xe_asset_code did not match
                     entity base currency asset code";
            }
        }
        else
        {
            die "Sorry, missing xe_asset_quantity in TXN::ModWallet of
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
method get_raw_value() returns FatRat:D
{
    # get DecInc
    my DecInc $decinc = $.decinc;

    # get value
    my Quantity $value = self.get_value;

    # convert to raw FatRat value
    my FatRat $raw_value = $decinc ~~ INC ?? $value !! -$value;
}

# vim: ft=perl6
