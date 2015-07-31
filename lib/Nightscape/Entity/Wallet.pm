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
method clone() returns Nightscape::Entity::Wallet:D
{
    my Array[Nightscape::Entity::Wallet::Changeset] %balance{AssetCode} =
        self.clone_balance;
    my Nightscape::Entity::Wallet %subwallet{VarName} =
        %.subwallet.deepmap(*.clone);
    my Nightscape::Entity::Wallet $wallet .= new(:%balance, :%subwallet);
    $wallet;
}

# clone changesets indexed by asset code with explicit instantiation
method clone_balance(
) returns Hash[Array[Nightscape::Entity::Wallet::Changeset:D],AssetCode:D]
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
    AssetCode:D :$asset_code!,    # get wallet balance for this asset code
    AssetCode :$base_currency,    # (optional) request results in $base_currency
    Bool :$recursive              # (optional) recursively query subwallets
) returns Rat:D
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
            if defined $base_currency
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
            # the :base_currency parameter must always be passed to
            # Wallet.get_balance
            my AssetCode $bc = defined($base_currency) ?? $base_currency !! Nil;

            # add subwallet balance to $balance
            for %.subwallet.kv -> $name, $subwallet
            {
                $balance += $subwallet.get_balance(
                    :$asset_code,
                    :base_currency($bc),
                    :recursive
                );
            }
        }
    }

    $balance;
}

# list all assets handled
method ls_assets() returns Array[AssetCode:D]
{
    my AssetCode @assets_handled = %.balance.keys;
}

# list UUIDs handled, indexed by asset code (default: entry UUID)
method ls_assets_with_uuids(
    Bool :$posting
) returns Hash[Array[UUID:D],AssetCode:D]
{
    # store UUIDs handled, indexed by asset code
    my Array[UUID] %uuids_handled_by_asset_code{AssetCode};

    # list all assets handled
    my AssetCode @assets_handled = self.ls_assets;

    # for each asset code handled
    for @assets_handled -> $asset_code
    {
        # was :posting arg passed?
        if $posting
        {
            # get posting UUIDs handled by asset code
            %uuids_handled_by_asset_code{$asset_code} = self.ls_uuids(
                :$asset_code,
                :posting
            );
        }
        else
        {
            # get entry UUIDs handled by asset code
            %uuids_handled_by_asset_code{$asset_code} = self.ls_uuids(
                :$asset_code
            );
        }
    }

    %uuids_handled_by_asset_code;
}

# list changesets
method ls_changesets(
    AssetCode:D :$asset_code!,
    UUID :$entry_uuid,
    UUID :$posting_uuid
) returns Array[Nightscape::Entity::Wallet::Changeset]
{
    my Nightscape::Entity::Wallet::Changeset @c = %.balance{$asset_code}.list;
    @c = self._ls_changesets(:changesets(@c), :$entry_uuid) if $entry_uuid;
    @c = self._ls_changesets(:changesets(@c), :$posting_uuid) if $posting_uuid;
    @c;
}

multi method _ls_changesets(
    Nightscape::Entity::Wallet::Changeset:D :@changesets! is readonly,
    UUID:D :$entry_uuid!
) returns Array[Nightscape::Entity::Wallet::Changeset]
{
    my Nightscape::Entity::Wallet::Changeset @c = @changesets.grep({
        .entry_uuid ~~ $entry_uuid
    });
}

multi method _ls_changesets(
    Nightscape::Entity::Wallet::Changeset:D :@changesets! is readonly,
    UUID:D :$posting_uuid!
) returns Array[Nightscape::Entity::Wallet::Changeset]
{
    my Nightscape::Entity::Wallet::Changeset @c = @changesets.grep({
        .posting_uuid ~~ $posting_uuid
    });
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

# record balance update instruction, the final executor (standard mode)
multi method mkchangeset(
    UUID:D :$entry_uuid!,
    UUID :$posting_uuid!,           # is undefined for NSAutoCapitalGains
    AssetCode:D :$asset_code!,
    DecInc:D :$decinc!,
    Quantity:D :$quantity!,
    AssetCode :$xe_asset_code,
    Quantity :$xe_asset_quantity
)
{
    # store delta by which to change wallet balance of asset code
    my Rat $balance_delta;

    # store asset code of balance delta
    my AssetCode $balance_delta_asset_code = $asset_code;

    # INC?
    if $decinc ~~ INC
    {
        # balance +
        $balance_delta = $quantity;
    }
    # DEC?
    elsif $decinc ~~ DEC
    {
        # balance -
        $balance_delta = -$quantity;
    }

    # instantiate changeset and append to list %.balance{$asset_code}
    push %!balance{$asset_code}, Nightscape::Entity::Wallet::Changeset.new(
        :$balance_delta,
        :$balance_delta_asset_code,
        :$entry_uuid,
        :$posting_uuid,
        :$xe_asset_code,
        :$xe_asset_quantity
    );
}

# record balance update instruction, the final executor (splice mode)
multi method mkchangeset(
    UUID:D :$entry_uuid!,
    UUID:D :$posting_uuid!,
    AssetCode:D :$asset_code!,
    DecInc:D :$decinc!,
    Quantity:D :$quantity!,
    AssetCode :$xe_asset_code,
    Quantity :$xe_asset_quantity,
    Bool:D :$splice! where *.so, # :splice arg must be explicitly passed
    Int:D :$index! # index at which to insert new Changeset in changesets list
)
{
    # store delta by which to change wallet balance of asset code
    my Rat $balance_delta;

    # store asset code of balance delta
    my AssetCode $balance_delta_asset_code = $asset_code;

    # INC?
    if $decinc ~~ INC
    {
        # balance +
        $balance_delta = $quantity;
    }
    # DEC?
    elsif $decinc ~~ DEC
    {
        # balance -
        $balance_delta = -$quantity;
    }

    # instantiate changeset
    my Nightscape::Entity::Wallet::Changeset $changeset .= new(
        :$balance_delta,
        :$balance_delta_asset_code,
        :$entry_uuid,
        :$posting_uuid,
        :$xe_asset_code,
        :$xe_asset_quantity
    );

    # splice changeset
    %!balance{$asset_code}.splice($index, 0, $changeset);
}

# modify existing changeset given asset code, entry UUID, posting UUID
# and instruction:
#
#     MOD | AcctName | QuantityToDebit | XE
#
multi method mkchangeset(
    AssetCode:D :$asset_code!,
    AssetCode:D :$xe_asset_code!,
    UUID:D :$entry_uuid!,
    UUID:D :$posting_uuid!, # posting UUID of which to modify
    Instruction:D :$instruction! (
        # deconstruct instruction
        AssetsAcctName:D :$acct_name!,
        NewMod:D :$newmod! where * ~~ MOD,
        UUID:D :posting_uuid($posting_uuid_instr)!,
        Quantity:D :$quantity_to_debit!,
        Quantity :xe($xe_asset_quantity) # optional in certain cases
    )
)
{
    # ensure Instruction posting UUID matches the causal posting UUID
    unless $posting_uuid ~~ $posting_uuid_instr
    {
        # error: Instruction posting UUID does not match causal posting UUID
        die "Sorry, Instruction posting UUID does not match causal posting UUID";
    }

    # changesets matching posting uuid under asset code
    my Nightscape::Entity::Wallet::Changeset @changesets = self.ls_changesets(
        :$asset_code,
        :$posting_uuid
    );

    # was there not exactly one matching changeset?
    unless @changesets.elems == 1
    {
        # no matches?
        if @changesets.elems < 1
        {
            # error: no matching changeset found
            die "Sorry, could not find changeset with matching posting UUID";
        }
        # more than one match?
        elsif @changesets.elems > 1
        {
            # error: more than one changeset found sharing posting UUID
            die "Sorry, got more than one changeset with same posting UUID";
        }
    }

    # choose only element in the list of changesets
    my Nightscape::Entity::Wallet::Changeset $changeset := @changesets[0];

    # new Changeset.balance_delta
    my Rat $balance_delta = -$quantity_to_debit; # negated, debiting ASSETS silo

    # update this Changeset.balance_delta
    $changeset.mkbalance_delta(:$balance_delta, :force);

    # update this Changeset.xe_asset_code
    #
    # `if` supports cases where a Bucket has part of its original capacity
    # remaining, which entails only adjusting the Changeset.balance_delta
    $changeset.mkxeaq(:$xe_asset_quantity, :force) if $xe_asset_quantity;
}

# create changeset given asset code, entry UUID, posting UUID and instruction:
#
#     NEW | AcctName | QuantityToDebit | XE
#
multi method mkchangeset(
    AssetCode:D :$asset_code!,
    AssetCode:D :$xe_asset_code!,
    UUID:D :$entry_uuid!,
    UUID:D :$posting_uuid!, # parent posting UUID, needed for calculating $index
    Instruction:D :$instruction! (
        # deconstruct instruction
        AssetsAcctName:D :$acct_name!,
        NewMod:D :$newmod! where * ~~ NEW,
        UUID:D :posting_uuid($posting_uuid_instr)!,
        Quantity:D :quantity_to_debit($quantity)!,
        Quantity:D :xe($xe_asset_quantity)! # required for NEW Instructions
    )
)
{
    # ensure Instruction posting UUID matches the causal posting UUID
    unless $posting_uuid ~~ $posting_uuid_instr
    {
        # error: Instruction posting UUID does not match causal posting UUID
        die "Sorry, Instruction posting UUID does not match causal posting UUID";
    }

    # we always need to have an $xe_asset_quantity here because this
    # method is for balancing silo ASSETS wallet
    # C<Changeset.balance_delta>s and C<Changeset.xe_asset_quantity>s
    # to allow for incising INCOME:NSAutoCapitalGains
    unless $xe_asset_quantity
    {
        # error: missing xe_asset_quantity for NEW Instruction
        die "Sorry, missing xe_asset_quantity for NewMod::NEW Instruction";
    }

    # it must be a DEC, since only those postings with net outflow of
    # asset in wallet of silo ASSETS are being incised for balancing of
    # realized capital gains / losses
    my DecInc $decinc = DEC;

    # target index is after parent posting UUID index
    my Int $index = 1 + %.balance{$asset_code}.first-index({
        .posting_uuid ~~ $posting_uuid
    });

    # create new posting UUID
    my UUID $new_posting_uuid .= new;

    # splice balance update instruction next to parent posting UUID's
    # location in %.balance{$asset_code} array
    self.mkchangeset(
        :$entry_uuid,
        :posting_uuid($new_posting_uuid),
        :$asset_code,
        :$decinc,
        :$quantity,
        :$xe_asset_code,
        :$xe_asset_quantity
        :splice, :$index
    );
}

# list nested wallets/subwallets as hash of wallet names
multi method tree(Bool:D :$hash! where *.so) returns Hash
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
multi method tree(%tree) returns Array[Array[VarName:D]]
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

    sub grind(%tree, Str :$carry = "") returns Array[AcctName:D]
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
