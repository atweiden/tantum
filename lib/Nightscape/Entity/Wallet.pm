use v6;
use Nightscape::Entity::Wallet::Changeset;
use Nightscape::Types;
use UUID;
unit class Nightscape::Entity::Wallet;

# append-only list of balance changesets, indexed by asset code
has Array[Nightscape::Entity::Wallet::Changeset] %.balance{AssetCode};

# subwallet, indexed by name
has Nightscape::Entity::Wallet %.subwallet{VarName};

# clone balance and subwallets with explicit instantiation and deepmap
method clone() returns Nightscape::Entity::Wallet
{
    my Array[Nightscape::Entity::Wallet::Changeset] %balance{AssetCode}
        = self.clone_balance;
    my Nightscape::Entity::Wallet %subwallet{VarName} =
        %.subwallet.deepmap(*.clone);
    my Nightscape::Entity::Wallet $wallet .= new(:%balance, :%subwallet);
    $wallet;
}

# clone changesets indexed by asset code with explicit instantiation
method clone_balance(
) returns Hash[Array[Nightscape::Entity::Wallet::Changeset],AssetCode]
{
    my Array[Nightscape::Entity::Wallet::Changeset] %balance{AssetCode};
    for %.balance.keys -> $asset_code
    {
        for %.balance{$asset_code}.list -> $changeset
        {
            push %balance{$asset_code},
                Nightscape::Entity::Wallet::Changeset.new(
                    :balance_delta($changeset.balance_delta),
                    :balance_delta_asset_code($changeset.balance_delta_asset_code),
                    :entry_uuid($changeset.entry_uuid),
                    :posting_uuid($changeset.posting_uuid),
                    :xe_asset_code($changeset.xe_asset_code),
                    :xe_asset_quantity($changeset.xe_asset_quantity)
                )
        }
    }
    %balance;
}

# get wallet balance
method get_balance(
    AssetCode :$asset_code!,      # get wallet balance for this asset code
    Str :$base_currency,          # (optional) request results in $base_currency
                                  # When typecheck: AssetCode => Constraint type check failed for parameter '$base_currency'
    Bool :$recursive              # (optional) recursively query subwallets
) returns Rat
{
    my Rat $balance;
    my Rat @deltas;

    # does this wallet have a balance for asset code?
    if %.balance{$asset_code}
    {
        # calculate balance (sum changeset balance deltas)
        for %.balance{$asset_code}.list -> $changeset
        {
            # convert balance into $base_currency?
            if $base_currency
            {
                # does posting's asset code match the requested base currency?
                if $changeset.balance_delta_asset_code ~~ $base_currency
                {
                    # use posting's main asset code instead of looking up xe
                    push @deltas, $changeset.balance_delta;
                }
                else
                {
                    # does delta exchange rate's asset code match the
                    # requested base currency?
                    my AssetCode $xeac = $changeset.xe_asset_code;
                    unless $xeac ~~ $base_currency
                    {
                        # error: exchange rate data missing from changeset
                        die qq:to/EOF/;
                        Sorry, suitable exchange rate was missing for base currency
                        in changeset:

                        「$changeset」

                        Changeset defaults to balance delta for asset code: 「$asset_code」
                        Changeset includes exchange rate for asset code: 「$xeac」
                        but you requested a result in asset code: 「$base_currency」

                        Asset code $xeac exchange rate data is sourced from
                        transaction journal entry posting's exchange rate.
                        This exchange rate should either be included in
                        the original transaction journal file, or from the
                        price data configured.
                        EOF
                    }

                    # multiply changeset default balance delta by exchange rate
                    my Rat $balance_delta =
                        $changeset.balance_delta * $changeset.xe_asset_quantity;

                    # use balance figure converted to $base_currency
                    push @deltas, $balance_delta;
                }

            }
            else
            {
                # default to using changeset's main balance delta
                # in asset code: 「Posting.amount.asset_code」
                push @deltas, $changeset.balance_delta;
            }
        }

        # sum balance deltas
        $balance = [+] @deltas;
    }
    else
    {
        # balance is zero
        $balance = 0.0;
    }


    # recurse?
    if $recursive
    {
        # is there a subwallet?
        if %.subwallet
        {
            # add subwallet balance to $balance
            for %.subwallet.kv -> $name, $subwallet
            {
                $balance += $subwallet.get_balance(
                    :$asset_code,
                    :$base_currency,
                    :recursive
                );
            }
        }
    }

    $balance;
}

# list all assets handled
method ls_assets() returns Array[AssetCode]
{
    my AssetCode @assets_handled = %.balance.keys;
}

# list UUIDs handled, indexed by asset code (default: entry UUID)
method ls_assets_with_uuids(Bool :$posting) returns Hash[Array[UUID],AssetCode]
{
    # store UUIDs handled, indexed by asset code
    my Array[UUID] %uuids_handled_by_asset_code{AssetCode};

    # list all assets handled
    my AssetCode @assets_handled = self.ls_assets;

    # for each asset code handled
    for @assets_handled -> $asset_code
    {
        if $posting
        {
            %uuids_handled_by_asset_code{$asset_code} = self.ls_uuids(
                :$asset_code,
                :posting
            );
        }
        else
        {
            %uuids_handled_by_asset_code{$asset_code} = self.ls_uuids(
                :$asset_code
            );
        }
    }

    %uuids_handled_by_asset_code;
}

# list UUIDs handled (default: entry UUID)
method ls_uuids(Str :$asset_code, Bool :$posting) returns Array[UUID]
{
    # populate assets handled
    my AssetCode @assets_handled;
    $asset_code
        ?? (@assets_handled = $asset_code)
        !! (@assets_handled = self.ls_assets);

    # store UUIDs handled
    my UUID @uuids_handled;

    # fetch UUIDs handled
    for @assets_handled -> $asset_code
    {
        for %.balance{$asset_code} -> @changesets
        {
            for @changesets -> $changeset
            {
                # requested posting UUIDs?
                if $posting
                {
                    # gather causal posting UUIDs
                    push @uuids_handled, $changeset.posting_uuid;
                }
                else
                {
                    # gather causal entry UUIDs
                    push @uuids_handled, $changeset.entry_uuid;
                }
            }
        }
    }

    @uuids_handled;
}

# record balance update instruction
method mkchangeset(
    UUID :$entry_uuid!,
    UUID :$posting_uuid!,
    AssetCode :$asset_code!,
    DecInc :$decinc!,
    Quantity :$quantity!,
    AssetCode :$xe_asset_code,
    Quantity :$xe_asset_quantity
)
{
    # INC?
    if $decinc ~~ INC
    {
        # balance +
        push %!balance{$asset_code}, Nightscape::Entity::Wallet::Changeset.new(
            :balance_delta($quantity),
            :balance_delta_asset_code($asset_code),
            :$entry_uuid,
            :$posting_uuid,
            :$xe_asset_code,
            :$xe_asset_quantity
        );
    }
    # DEC?
    elsif $decinc ~~ DEC
    {
        # balance -
        push %!balance{$asset_code}, Nightscape::Entity::Wallet::Changeset.new(
            :balance_delta(-$quantity),
            :balance_delta_asset_code($asset_code),
            :$entry_uuid,
            :$posting_uuid,
            :$xe_asset_code,
            :$xe_asset_quantity
        );
    }
}

# update xe_asset_quantity in one Entry's changesets (by entry UUID)
method mod_xeaq(
    AssetCode :$asset_code!,
    UUID :$entry_uuid!,
    Quantity :$xe_asset_quantity!
)
{
    for %.balance{$asset_code}.grep({ .entry_uuid ~~ $entry_uuid })
    {
        my Nightscape::Entity::Wallet::Changeset $changeset := $^a;
        $changeset.mkxeaq(:$xe_asset_quantity, :force);
    }
}

# list nested wallets/subwallets as hash of wallet names
multi method tree(Bool :$hash!) returns Hash
{
    my %tree;
    sub deref(%tree, *@k) is rw
    {
        my $h := %tree;
        $h := $h{$_} for @k;
        $h;
    }
    deref(%tree, $_) = %.subwallet{$_}.tree(:hash) for %.subwallet.keys;
    %tree;
}

# list nested wallets/subwallets as list of wallet names for easy access
multi method tree(%tree) returns Array[Array[VarName]]
{
    #
    # incoming:
    #     {
    #         :Bankwest({
    #             :Cheque({
    #                 :ABC({}),
    #                 :DEF({
    #                     :XYZ({})
    #                 })
    #             })
    #         }),
    #         :BitBroker({})
    #     }<>
    #
    # outgoing:
    #
    #     ["Bankwest"],
    #     ["Bankwest", "Cheque"],
    #     ["Bankwest", "Cheque", "ABC"],
    #     ["Bankwest", "Cheque", "DEF"],
    #     ["Bankwest", "Cheque", "DEF", "XYZ"],
    #     ["BitBroker"]
    #

    sub grind(%tree, Str :$carry = "") returns Array[AcctName]
    {
        my AcctName @acct_names;
        for %tree.keys -> $toplevel
        {
            my AcctName $acct_name = $carry ~ $toplevel ~ ':';
            if %tree{$toplevel} ~~ Hash
            {
                push @acct_names,
                    $acct_name,
                    grind(
                        %tree{$toplevel},
                        :carry($acct_name)
                    );
            }
            else
            {
                push @acct_names, %tree{$toplevel};
            }
        }
        @acct_names;
    }

    # grind hash into strings
    my AcctName @acct_names = grind(%tree);

    # trim trailing ':'
    @acct_names .= map({ substr($_, 0, *-1) });

    # convert each nested wallet path string to type: Array[VarName]
    my Array[VarName] @tree;
    for @acct_names -> $acct_name
    {
        # coerce to type: Array
        my VarName @acct_path = Array($acct_name.split(':'));
        push @tree, $@acct_path;
    }

    # return sorted tree
    @tree .= sort;
}

# vim: ft=perl6
