use v6;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;

# class Account {{{

class Account
{
    has Array[Rat:D] %.balance{AssetCode:D};
    has Account:D %.subaccount{VarName:D};

    # --- method clone {{{

    proto method clone(|) {*}
    multi method clone(::?CLASS:D: --> Account:D)
    {
        my Array[Rat:D] %balance{AssetCode:D} =
            %.balance.kv.hyper.map(->
                AssetCode:D $asset-code, Rat:D @delta {
                    $asset-code => @delta.clone
            });
        my Account:D %subaccount{VarName:D} =
            %.subaccount.kv.hyper.map(->
                VarName:D $subaccount-name, Account:D $account {
                    $subaccount-name => $account.clone
            });
        my Account $account .= new(:%balance, :%subaccount);
    }

    # --- end method clone }}}
    # --- method mkbalance {{{

    method mkbalance(::?CLASS:D: AssetCode:D $asset-code, Rat:D $delta --> Nil)
    {
        push(%!balance{$asset-code}, $delta);
    }

    # --- end method mkbalance }}}
    # --- method mksubaccount {{{

    method mksubaccount(::?CLASS:D: VarName:D $subaccount-name --> Nil)
    {
        %!subaccount{$subaccount-name} = Account.new;
    }

    # --- end method mksubaccount }}}
}

# end class Account }}}
# class Coa {{{

=begin pod
Maybe what this needs is a closure generator where missing items
include C<Account::Changeset>. or perhaps a function which returns
C<Account::Changeset>.
=end pod

class Coa
{
    # default is one account per C<Silo>
    has Account:D %.account{Silo:D} =
        Silo::.keys.hyper.map({ ::($_) }) Z=> Account.new xx Silo::.keys.elems;

    # --- method new {{{

    # new C<Coa> from C<Entry::Posting> and old C<Coa>
    multi method new(
        Coa:D :coa($c)!,
        Entry::Posting:D :$posting!
        --> Coa:D
    )
    {
        # clone new C<Coa> from old
        my Coa:D $coa = $c.clone;

        # get target account
        my Entry::Posting::Account:D $account = $posting.account;
        my Silo:D $silo = $account.silo;
        my VarName:D $entity = $account.entity;
        my VarName:D @path = $account.path;
        my Account:D $account-target =
            in-account($coa.account{$silo}, $entity, |@path);

        # get target amount
        my Entry::Posting::Amount:D $amount = $posting.amount;
        my AssetCode:D $asset-code = $amount.asset-code;
        my DecInc:D $decinc = $posting.decinc;
        my Int:D $multiplier = $decinc == INC ?? 1 !! -1;
        my Rat:D $delta = $amount.asset-quantity * $multiplier;
        $account-target.mkbalance($asset-code, $delta);

        $coa;
    }

    multi method new(
        :%account!
        --> Coa:D
    )
    {
        self.bless(:%account);
    }

    multi method new(
        *%
        --> Coa:D
    )
    {
        self.bless;
    }

    # --- end method new }}}
    # --- method clone {{{

    proto method clone(|) {*}
    multi method clone(::?CLASS:D: --> Coa:D)
    {
        my Account:D %account{Silo:D} =
            %.account.kv.hyper.map(-> Silo:D $silo, Account:D $account {
                $silo => $account.clone
            });
        my Coa $coa .= new(:%account);
    }

    # --- end method clone }}}
}

# end class Coa }}}
# class Hodl {{{

class Hodl {*}

# end class Hodl }}}
# class Entryʹ {{{

class Entryʹ
{
    # C<Entry> from which C<Entry′> is derived
    has Entry:D $.entry is required;
    has Entry::Postingʹ:D @.postingʹ is required;
    has Coa:D $.coa is required;
    has Hodl:D $.hodl is required;

    method new(Entry:D $entry, Entry::Postingʹ:D @postingʹ --> Entryʹ:D)
    {
        my %bless = apply-hooks($entry, @postingʹ);
        self.bless(|%bless);
    }
}

# end class Entryʹ }}}
# class Entry::Postingʹ {{{

class Entry::Postingʹ
{
    # C<Entry::Posting> from which C<Entry::Posting′> is derived
    has Entry::Posting:D $.posting is required;
    has Coa:D $.coa is required;
    has Hodl:D $.hodl is required;

    method made(::?CLASS:D: --> Hash:D)
    {
        my %made = :$.coa, :$.hodl;
    }
}

# end class Entry::Postingʹ }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
