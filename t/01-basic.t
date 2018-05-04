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

class Account
{
    has Array[Rat:D] %.balance{AssetCode:D} is rw;
    has Account:D %.subaccount{VarName:D} is rw;
}

# class ChartOfAccounts {{{

class ChartOfAccounts
{
    # default is one account per C<Silo>
    has Account:D %.account{Silo:D} is rw =
        Silo::.keys.hyper.map({ ::($_) }) Z=> Account.new xx Silo::.keys.elems;

    # new C<ChartOfAccounts> from C<Entry::Posting> and old C<ChartOfAccounts>
    multi method new(
        ChartOfAccounts:D :coa($c)!,
        Entry::Posting:D :$posting!
        --> ChartOfAccounts:D
    )
    {
        # create new C<ChartOfAccounts> from existing
        my ChartOfAccounts $coa .= new(:account($c.account));

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
        my Rat:D $asset-quantity = $amount.asset-quantity * $multiplier;
        push($account-target.balance{$asset-code}, $asset-quantity);

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
}

# end class ChartOfAccounts }}}
# class Hodl {{{

class Hodl
{*}

# end class Hodl }}}

# sub gen-entry-derivative {{{

multi sub gen-entry-derivative(
    Entry:D @entry
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
    my %entry-derivative = gen-entry-derivative(@tail, |%e);
}

multi sub gen-entry-derivative(
    @,
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
    my %entry-derivative = |%posting-derivative;
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
    my %posting-derivative = gen-posting-derivative(@tail, |%p);
}

multi sub gen-posting-derivative(
    @,
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
        $subaccount-name where {
            $account.subaccount.so
                    and $account.subaccount{$subaccount-name}:exists
        },
        *@tail
    )
) is rw
{
    my Account:D $subaccount := $account.subaccount{$subaccount-name};
    in-account($subaccount, @tail);
}

multi sub in-account(
    Account:D $account,
    *@subaccount ($subaccount-name, *@tail)
) is rw
{
    $account.subaccount{$subaccount-name} = Account.new;
    in-account($account, @subaccount);
}

multi sub in-account(
    Account:D $account,
    *@
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
