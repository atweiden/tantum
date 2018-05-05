use v6;
use lib 'lib';
use Nightscape;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
use lib 't/lib';
use NightscapeTest;

my %setup = NightscapeTest.setup;
my Nightscape $nightscape .= new(|%setup);
my List:D $pkg = $nightscape.sync;
my Entry:D @entry = $pkg.first<entry>.&ls-entries(:sort);

# p6doc {{{

=begin pod
=head SUBROUTINES

=head2 C<gen-entry-derivative>

C<gen-entry-derivative> chains C<$coa>, C<$hodl>, and C<@patch> through
related subroutines.

C<$coa> contains C<ChartOfAccounts>.

C<$hodl> contains C<Holdings>, which tracks entity holdings for
acquisition and disbursal.

C<$coa> and C<$hodl> are modified
L<Faux-O|https://www.destroyallsoftware.com/talks/boundaries> style while
C<@patch> accrues patch sets. Patch sets are reflective of modification
history to C<$coa> and C<$hodl>.
=end pod

# end p6doc }}}

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
# class ChartOfAccounts {{{

=begin pod
maybe what this needs is a closure generator where missing items
include C<Account::Changeset>. or perhaps a function which returns
C<Account::Changeset>.
=end pod

class ChartOfAccounts
{
    # default is one account per C<Silo>
    has Account:D %.account{Silo:D} =
        Silo::.keys.hyper.map({ ::($_) }) Z=> Account.new xx Silo::.keys.elems;

    # --- method new {{{

    # new C<ChartOfAccounts> from C<Entry::Posting> and old C<ChartOfAccounts>
    multi method new(
        ChartOfAccounts:D :coa($c)!,
        Entry::Posting:D :$posting!
        --> ChartOfAccounts:D
    )
    {
        # clone new C<ChartOfAccounts> from old
        my ChartOfAccounts:D $coa = $c.clone;

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
        --> ChartOfAccounts:D
    )
    {
        self.bless(:%account);
    }

    multi method new(
        *%
        --> ChartOfAccounts:D
    )
    {
        self.bless;
    }

    # --- end method new }}}
    # --- method clone {{{

    proto method clone(|) {*}
    multi method clone(::?CLASS:D: --> ChartOfAccounts:D)
    {
        my Account:D %account{Silo:D} =
            %.account.kv.hyper.map(-> Silo:D $silo, Account:D $account {
                $silo => $account.clone
            });
        my ChartOfAccounts $coa .= new(:%account);
    }

    # --- end method clone }}}
}

# end class ChartOfAccounts }}}
# class Hodl {{{

class Hodl
{*}

# end class Hodl }}}

# sub gen-entry-derivative {{{

multi sub gen-entry-derivative(
    Entry:D @entry (Entry:D $, *@),
    --> Hash:D
)
{
    my ChartOfAccounts $coa .= new;
    my Hodl $hodl .= new;
    my @patch;
    my %opts = :$coa, :$hodl, :@patch;
    my %entry-derivative = gen-entry-derivative(@entry, |%opts);
}

multi sub gen-entry-derivative(
    Entry:D @ (Entry:D $entry, *@tail),
    *%opts (
        ChartOfAccounts:D :coa($)!,
        Hodl:D :hodl($)!,
        :patch(@)!
    )
    --> Hash:D
)
{
    my %e = gen-entry-derivative($entry, |%opts);
    my Entry:D @entry = |@tail;
    my %entry-derivative = gen-entry-derivative(@entry, |%e);
}

multi sub gen-entry-derivative(
    Entry:D @,
    *%opts (
        ChartOfAccounts:D :coa($)!,
        Hodl:D :hodl($)!,
        :patch(@)!
    )
    --> Hash:D
)
{
    my %entry-derivative = |%opts;
}

multi sub gen-entry-derivative(
    Entry:D $entry,
    *%opts (
        ChartOfAccounts:D :coa($)!,
        Hodl:D :hodl($)!,
        :patch(@)!
    )
    --> Hash:D
)
{
    my Entry::Posting:D @posting = $entry.posting;
    my %posting-derivative = gen-posting-derivative(@posting, |%opts);
    # inspect aggregate entry postings for adjustments to C<$hodl>
    my %entry-derivative = %posting-derivative;
}

# end sub gen-entry-derivative }}}
# sub gen-posting-derivative {{{

multi sub gen-posting-derivative(
    Entry::Posting:D @ (Entry::Posting:D $posting, *@tail),
    *%opts (
        ChartOfAccounts:D :coa($)!,
        Hodl:D :hodl($)!,
        :patch(@)!
    )
    --> Hash:D
)
{
    my %p = gen-posting-derivative($posting, |%opts);
    my Entry::Posting:D @posting = |@tail;
    my %posting-derivative = gen-posting-derivative(@posting, |%p);
}

multi sub gen-posting-derivative(
    Entry::Posting:D @,
    *%opts (
        ChartOfAccounts:D :coa($)!,
        Hodl:D :hodl($)!,
        :patch(@)!
    )
    --> Hash:D
)
{
    my %posting-derivative = |%opts;
}

multi sub gen-posting-derivative(
    Entry::Posting:D $posting,
    ChartOfAccounts:D :coa($c)!,
    Hodl:D :$hodl!,
    :patch(@p)!
    --> Hash:D
)
{
    my ChartOfAccounts $coa .= new(:coa($c), :$posting);
    my %patch;
    my @patch = |@p, %patch;
    my %posting-derivative = :$coa, :$hodl, :@patch;
}

# end sub gen-posting-derivative }}}
# sub in-account {{{

multi sub in-account(
    Account:D $account,
    *@ (
        VarName:D $subaccount-name where { $account.subaccount{$_}:exists },
        *@tail
    )
    --> Account:D
) is rw
{
    my Account:D $subaccount := $account.subaccount{$subaccount-name};
    my VarName:D @subaccount = @tail;
    in-account($subaccount, @subaccount);
}

multi sub in-account(
    Account:D $account,
    *@s (
        VarName:D $subaccount-name,
        *@
    )
    --> Account:D
) is rw
{
    $account.mksubaccount($subaccount-name);
    my VarName:D @subaccount = @s;
    in-account($account, @subaccount);
}

multi sub in-account(
    Account:D $account,
    *@
    --> Account:D
) is rw
{
    $account;
}

# end sub in-account }}}
# sub ls-entries {{{

multi sub ls-entries(Entry:D @e, Bool:D :sort($)! where .so --> Array[Entry:D])
{
    # entries, sorted by date ascending then by importance descending
    my Entry:D @entry =
        @e
        .sort({ $^b.header.important > $^a.header.important })
        .sort({ .header.date });
}

multi sub ls-entries(Entry:D @e, Bool :sort($) --> Array[Entry:D])
{
    my Entry:D @entry = @e;
}

# end sub ls-entries }}}

my %entry-derivative = gen-entry-derivative(@entry);
%entry-derivative.perl.say;

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
