use v6;
use Nightscape::Entity::Wallet::Changeset;
use Nightscape::Types;
unit class Nightscape::Entity::Wallet;

# append-only list of balance changesets, indexed by asset code
has Array[Nightscape::Entity::Wallet::Changeset:D] %.balance{AssetCode:D};

# subwallet, indexed by name
has Nightscape::Entity::Wallet:D %.subwallet{VarName:D};

# clone balance and subwallets with explicit instantiation and deepmap
method clone() returns Nightscape::Entity::Wallet:D
{
    my Array[Nightscape::Entity::Wallet::Changeset:D] %balance{AssetCode:D} =
        self.clone-balance;
    my Nightscape::Entity::Wallet:D %subwallet{VarName:D} =
        %.subwallet.deepmap(*.clone);
    my Nightscape::Entity::Wallet $wallet .= new(:%balance, :%subwallet);
    $wallet;
}

# clone changesets indexed by asset code with explicit instantiation
method clone-balance(
) returns Hash[Array[Nightscape::Entity::Wallet::Changeset:D],AssetCode:D]
{
    my Array[Nightscape::Entity::Wallet::Changeset:D] %balance{AssetCode:D};
    for %.balance.keys -> $asset-code
    {
        for %.balance{$asset-code}.list -> $changeset
        {
            push %balance{$asset-code},
                Nightscape::Entity::Wallet::Changeset.new(
                    :balance-delta($changeset.balance-delta),
                    :balance-delta-asset-code($changeset.balance-delta-asset-code),
                    :entry-id($changeset.entry-id),
                    :posting-id($changeset.posting-id),
                    :xe-asset-code($changeset.xe-asset-code),
                    :xe-asset-quantity($changeset.xe-asset-quantity)
                )
        }
    }
    %balance;
}

# get wallet balance
method get-balance(
    AssetCode:D :$asset-code!,    # get wallet balance for this asset code
    AssetCode :$base-currency,    # (optional) request results in $base-currency
    Bool :$recursive              # (optional) recursively query subwallets
) returns FatRat:D                # returns 0.0 if asset code does not exist
{
    my FatRat $balance;
    my FatRat @deltas;

    # does this wallet have a balance for asset code?
    if try {%.balance{$asset-code}}
    {
        # calculate balance (sum changeset balance deltas)
        for %.balance{$asset-code}.list -> $changeset
        {
            # convert balance into $base-currency?
            if defined $base-currency
            {
                # does posting's asset code match the requested base currency?
                if $changeset.balance-delta-asset-code ~~ $base-currency
                {
                    # use posting's main asset code instead of looking up xe
                    push @deltas, $changeset.balance-delta;
                }
                else
                {
                    # does delta exchange rate's asset code match the
                    # requested base currency?
                    my AssetCode $xeac = $changeset.xe-asset-code;
                    unless $xeac ~~ $base-currency
                    {
                        # error: exchange rate data missing from changeset
                        die qq:to/EOF/;
                        Sorry, suitable exchange rate was missing for base currency
                        in changeset:

                        「{$changeset.perl}」

                        Changeset defaults to balance delta for asset code: 「$asset-code」
                        Changeset includes exchange rate for asset code: 「$xeac」
                        but you requested a result in asset code: 「$base-currency」

                        Asset code $xeac exchange rate data is sourced from
                        transaction journal entry posting's exchange rate.
                        This exchange rate should either be included in
                        the original transaction journal file, or from the
                        price data configured.
                        EOF
                    }

                    # multiply changeset default balance delta by exchange rate
                    my FatRat $balance-delta =
                        $changeset.balance-delta * $changeset.xe-asset-quantity;

                    # use balance figure converted to $base-currency
                    push @deltas, $balance-delta;
                }

            }
            else
            {
                # default to using changeset's main balance delta
                # in asset code: 「Posting.amount.asset-code」
                push @deltas, $changeset.balance-delta;
            }
        }

        # sum balance deltas
        $balance = [+] @deltas;
    }
    else
    {
        # balance is zero
        $balance = FatRat(0.0);
    }


    # recurse?
    if $recursive
    {
        # is there a subwallet?
        if try {defined(%.subwallet)}
        {
            # the :base-currency parameter must always be passed to
            # Wallet.get-balance
            my AssetCode $bc = defined($base-currency) ?? $base-currency !! Nil;

            # add subwallet balance to $balance
            for %.subwallet.kv -> $name, $subwallet
            {
                $balance += $subwallet.get-balance(
                    :$asset-code,
                    :base-currency($bc),
                    :recursive
                );
            }
        }
    }

    $balance;
}

# list all assets handled
method ls-assets() returns Array[AssetCode:D]
{
    my AssetCode:D @assets-handled = %.balance.keys;
}

# list EntryIDs handled, indexed by asset code
multi method ls-assets-with-ids() returns Hash[Array[EntryID:D],AssetCode:D]
{
    # store EntryIDs handled, indexed by asset code
    my Array[EntryID:D] %entry-ids-handled-by-asset-code{AssetCode:D};

    # list all assets handled
    my AssetCode:D @assets-handled = self.ls-assets;

    # for each asset code handled
    for @assets-handled -> $asset-code
    {
        # get EntryIDs handled by asset code
        %entry-ids-handled-by-asset-code{$asset-code} = self.ls-ids-by-asset(
            :$asset-code
        );
    }

    %entry-ids-handled-by-asset-code;
}

# list PostingIDs handled, indexed by asset code
multi method ls-assets-with-ids(
    Bool:D :$posting! where *.so
) returns Hash[Array[PostingID],AssetCode:D]
{
    # store PostingIDs handled, indexed by asset code
    my Array[PostingID] %posting-ids-handled-by-asset-code{AssetCode:D};

    # list all assets handled
    my AssetCode:D @assets-handled = self.ls-assets;

    # for each asset code handled
    for @assets-handled -> $asset-code
    {
        # get PostingIDs handled by asset code
        %posting-ids-handled-by-asset-code{$asset-code} =
            self.ls-ids-by-asset(:$asset-code, :posting);
    }

    %posting-ids-handled-by-asset-code;
}

# list changesets
method ls-changesets(
    AssetCode:D :$asset-code!,
    EntryID :$entry-id,
    PostingID :$posting-id
) returns Array[Nightscape::Entity::Wallet::Changeset]
{
    my Nightscape::Entity::Wallet::Changeset @c = %.balance{$asset-code}.list;
    @c = self._ls-changesets(:changesets(@c), :$entry-id) if $entry-id;
    @c = self._ls-changesets(:changesets(@c), :$posting-id) if $posting-id;
    @c;
}

multi method _ls-changesets(
    Nightscape::Entity::Wallet::Changeset:D :@changesets! is readonly,
    EntryID:D :$entry-id!
) returns Array[Nightscape::Entity::Wallet::Changeset]
{
    my Nightscape::Entity::Wallet::Changeset @c = @changesets.grep({
        .entry-id == $entry-id
    });
}

multi method _ls-changesets(
    Nightscape::Entity::Wallet::Changeset:D :@changesets! is readonly,
    PostingID:D :$posting-id!
) returns Array[Nightscape::Entity::Wallet::Changeset]
{
    my Nightscape::Entity::Wallet::Changeset @c = @changesets.grep({
        .posting-id == $posting-id
    });
}

# list EntryIDs handled, all asset codes
multi method ls-ids() returns Array[EntryID:D]
{
    # populate assets handled
    my AssetCode @assets-handled = self.ls-assets;

    # store EntryIDs handled
    my EntryID:D @entry-ids-handled;

    # fetch EntryIDs handled
    for @assets-handled -> $asset-code
    {
        push @entry-ids-handled, |self.ls-ids-by-asset(:$asset-code);
    }

    @entry-ids-handled;
}

# list PostingIDs handled, all asset codes
multi method ls-ids(Bool:D :$posting! where *.so) returns Array[PostingID]
{
    # populate assets handled
    my AssetCode @assets-handled = self.ls-assets;

    # store PostingIDs handled
    my PostingID @posting-ids-handled;

    # fetch PostingIDs handled
    for @assets-handled -> $asset-code
    {
        push @posting-ids-handled,
            |self.ls-ids-by-asset(:$asset-code, :$posting);
    }

    @posting-ids-handled;
}

# list EntryIDs handled, single asset code
multi method ls-ids-by-asset(
    AssetCode:D :$asset-code!,
    Bool:U :$posting
) returns Array[EntryID:D]
{
    # store EntryIDs handled
    my EntryID:D @entry-ids-handled;

    # fetch EntryIDs handled
    for %.balance{$asset-code} -> @changesets
    {
        for @changesets -> $changeset
        {
            push @entry-ids-handled, $changeset.entry-id;
        }
    }

    @entry-ids-handled;
}

# list PostingIDs handled, single asset code
multi method ls-ids-by-asset(
    AssetCode:D :$asset-code!,
    Bool:D :$posting! where *.so
) returns Array[PostingID]
{
    # store PostingIDs handled
    my PostingID @posting-ids-handled;

    # fetch PostingIDs handled
    for %.balance{$asset-code} -> @changesets
    {
        for @changesets -> $changeset
        {
            push @posting-ids-handled, $changeset.posting-id;
        }
    }

    @posting-ids-handled;
}

# record balance update instruction, the final executor (standard mode)
multi method mkchangeset(
    EntryID:D :$entry-id!,
    PostingID :$posting-id!,           # is undefined for NSAutoCapitalGains
    AssetCode:D :$asset-code!,
    DecInc:D :$decinc!,
    Quantity:D :$quantity!,
    AssetCode :$xe-asset-code,
    Quantity :$xe-asset-quantity
)
{
    # store delta by which to change wallet balance of asset code
    my FatRat $balance-delta;

    # store asset code of balance delta
    my AssetCode $balance-delta-asset-code = $asset-code;

    # INC?
    if $decinc ~~ INC
    {
        # balance +
        $balance-delta = $quantity;
    }
    # DEC?
    elsif $decinc ~~ DEC
    {
        # balance -
        $balance-delta = -$quantity;
    }

    # instantiate changeset and append to list %.balance{$asset-code}
    push %!balance{$asset-code}, Nightscape::Entity::Wallet::Changeset.new(
        :$balance-delta,
        :$balance-delta-asset-code,
        :$entry-id,
        :$posting-id,
        :$xe-asset-code,
        :$xe-asset-quantity
    );
}

# record balance update instruction, the final executor (splice mode)
multi method mkchangeset(
    EntryID:D :$entry-id!,
    PostingID:D :$posting-id!,
    AssetCode:D :$asset-code!,
    DecInc:D :$decinc!,
    Quantity:D :$quantity!,
    AssetCode :$xe-asset-code,
    Quantity :$xe-asset-quantity,
    Bool:D :$splice! where *.so, # :splice arg must be explicitly passed
    Int:D :$index! # index at which to insert new Changeset in changesets list
)
{
    # store delta by which to change wallet balance of asset code
    my FatRat $balance-delta;

    # store asset code of balance delta
    my AssetCode $balance-delta-asset-code = $asset-code;

    # INC?
    if $decinc ~~ INC
    {
        # balance +
        $balance-delta = $quantity;
    }
    # DEC?
    elsif $decinc ~~ DEC
    {
        # balance -
        $balance-delta = -$quantity;
    }

    # instantiate changeset
    my Nightscape::Entity::Wallet::Changeset $changeset .= new(
        :$balance-delta,
        :$balance-delta-asset-code,
        :$entry-id,
        :$posting-id,
        :$xe-asset-code,
        :$xe-asset-quantity
    );

    # splice changeset
    %!balance{$asset-code}.splice($index, 0, $changeset);
}

# modify existing changeset given asset code, EntryID, PostingID and
# instruction:
#
#     MOD | AcctName | QuantityToDebit | XE
#
multi method mkchangeset(
    AssetCode:D :$asset-code!,
    AssetCode:D :$xe-asset-code!,
    EntryID:D :$entry-id!,
    PostingID:D :$posting-id!, # PostingID of which to modify
    Instruction:D :$instruction! (
        # deconstruct instruction
        AssetsAcctName:D :$acct-name!,
        NewMod:D :$newmod! where * ~~ MOD,
        PostingID:D :posting-id($posting-id-instr)!,
        Quantity:D :$quantity-to-debit!,
        Quantity :xe($xe-asset-quantity) # optional in certain cases
    )
)
{
    # ensure Instruction PostingID matches the causal PostingID
    unless $posting-id == $posting-id-instr
    {
        # error: Instruction PostingID does not match causal PostingID
        die "Sorry, Instruction PostingID does not match causal PostingID";
    }

    # changesets matching PostingID under asset code
    my Nightscape::Entity::Wallet::Changeset @changesets = self.ls-changesets(
        :$asset-code,
        :$posting-id
    );

    # was there not exactly one matching changeset?
    unless @changesets.elems == 1
    {
        # no matches?
        if @changesets.elems < 1
        {
            # error: no matching changeset found
            die "Sorry, could not find changeset with matching PostingID";
        }
        # more than one match?
        elsif @changesets.elems > 1
        {
            # error: more than one changeset found sharing PostingID
            die "Sorry, got more than one changeset with same PostingID";
        }
    }

    # choose only element in the list of changesets
    my Nightscape::Entity::Wallet::Changeset $changeset := @changesets[0];

    # new Changeset.balance-delta
    # negated because we're debiting ASSETS silo
    my FatRat $balance-delta = -$quantity-to-debit;

    # update this Changeset.balance-delta
    $changeset.mkbalance-delta(:$balance-delta, :force);

    # update this Changeset.xe-asset-code
    #
    # `if` supports cases where a Bucket has part of its original capacity
    # remaining, which entails only adjusting the Changeset.balance-delta
    $changeset.mkxeaq(:$xe-asset-quantity, :force) if $xe-asset-quantity;
}

# create changeset given asset code, EntryID, PostingID and instruction:
#
#     NEW | AcctName | QuantityToDebit | XE
#
multi method mkchangeset(
    AssetCode:D :$asset-code!,
    AssetCode:D :$xe-asset-code!,
    EntryID:D :$entry-id!,
    PostingID:D :$posting-id!, # parent PostingID, needed for calculating $index
    Instruction:D :$instruction! (
        # deconstruct instruction
        AssetsAcctName:D :$acct-name!,
        NewMod:D :$newmod! where * ~~ NEW,
        PostingID:D :posting-id($posting-id-instr)!,
        Quantity:D :quantity-to-debit($quantity)!,
        Quantity:D :xe($xe-asset-quantity)! # required for NEW Instructions
    )
)
{
    # ensure Instruction PostingID matches the causal PostingID
    unless $posting-id == $posting-id-instr
    {
        # error: Instruction PostingID does not match causal PostingID
        die "Sorry, Instruction PostingID does not match causal PostingID";
    }

    # we always need to have an $xe-asset-quantity here because this
    # method is for balancing silo ASSETS wallet
    # C<Changeset.balance-delta>s and C<Changeset.xe-asset-quantity>s
    # to allow for incising INCOME:NSAutoCapitalGains
    unless $xe-asset-quantity
    {
        # error: missing xe-asset-quantity for NEW Instruction
        die "Sorry, missing xe-asset-quantity for NewMod::NEW Instruction";
    }

    # it must be a DEC, since only those postings with net outflow of
    # asset in wallet of silo ASSETS are being incised for balancing of
    # realized capital gains / losses
    my DecInc $decinc = DEC;

    # target index is after parent PostingID index
    my Int $index = 1 + %.balance{$asset-code}.first:
        *.posting-id == $posting-id, :k;

    # create new PostingID
    my PostingID $new-posting-id .= new(
        :$entry-id
        :number(-1),
        :text("NSAutoPostingID"),
        :xxhash(55555)
    );

    # splice balance update instruction next to parent PostingID's
    # location in %.balance{$asset-code} array
    self.mkchangeset(
        :$entry-id,
        :posting-id($new-posting-id),
        :$asset-code,
        :$decinc,
        :$quantity,
        :$xe-asset-code,
        :$xe-asset-quantity
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

    sub grind(%tree, Str :$carry = "") returns Array
    {
        my @acct-names;
        for %tree.keys -> $toplevel
        {
            my $acct-name = $carry ~ $toplevel ~ ':';
            if %tree{$toplevel} ~~ Hash
            {
                push @acct-names,
                    $acct-name,
                    |grind(
                        %tree{$toplevel},
                        :carry($acct-name)
                    );
            }
            else
            {
                push @acct-names, %tree{$toplevel};
            }
        }
        @acct-names;
    }

    # grind hash into strings
    my @acct-names = grind(%tree);

    # trim trailing ':'
    @acct-names .= map({ substr($_, 0, *-1) });

    # convert each nested wallet path string to type: Array[VarName]
    my Array[VarName:D] @tree;
    for @acct-names -> $acct-name
    {
        # coerce to type: Array
        my VarName:D @acct-path = Array($acct-name.split(':'));
        push @tree, @acct-path;
    }

    # return sorted tree
    @tree .= sort;
}

# vim: ft=perl6
