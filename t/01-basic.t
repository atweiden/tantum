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

=head2 C<gen-entryʹ>

C<gen-entryʹ> chains C<$coa>, C<$hodl>, and C<@patch> through
related subroutines.

c<$coa> contains entity I<Chart of Accounts>.

C<$hodl> contains C<Holdings>, which tracks entity holdings for
acquisition and disbursal.

C<$coa> and C<$hodl> are modified
L<Faux-O|https://www.destroyallsoftware.com/talks/boundaries> style.
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

# role Grep {{{

role Grep
{
    method is-match(--> Bool:D) {...}
}

role Grep::Entry['All']
{
    also does Grep;

    # match all entries
    method is-match(Entry:D $ --> Bool:D)
    {
        my Bool:D $is-match = True;
    }
}

role Grep::Entry::Posting['All']
{
    also does Grep;

    # match all postings
    method is-match(Entry::Posting:D $ --> Bool:D)
    {
        my Bool:D $is-match = True;
    }
}

# end role Grep }}}
# role Map {{{

role Map::Entry::Posting['All']
{
    method new(--> Entry::Posting′:D)
    {

    }
}

# end role Map }}}

# sub gen-entryʹ {{{

multi sub gen-entryʹ(
    Entry:D @entry (Entry:D $, *@),
    --> Array[Entryʹ:D]
)
{
    my Coa $coa .= new;
    my Hodl $hodl .= new;
    my %opts = :$coa, :$hodl;
    my Entryʹ:D @entryʹ = gen-entryʹ(@entry, %opts);
}

multi sub gen-entryʹ(
    Entry:D @ (Entry:D $entry, *@tail),
    %opts (
        Coa:D :coa($)!,
        Hodl:D :hodl($)!
    ),
    Entryʹ:D :carry(@c)
    --> Array[Entryʹ:D]
)
{
    # C<$entryʹ> is derivative of C<$entry> given Coa and Hodl
    my Entryʹ:D $entryʹ = gen-entryʹ($entry, %opts);
    # C<@entry> contains remaining C<Entry>s
    my Entry:D @entry = |@tail;
    # C<%made> contains latest state of Coa and Hodl
    my %made = $entryʹ.made;
    # we append C<$entryʹ> to C<@carry> and handle remaining C<Entry>s
    my Entryʹ:D @carry = |@c, $entryʹ;
    # next C<Entry> handled gets latest state of Coa and Hodl via C<%made>
    my Entryʹ:D @entryʹ = gen-entryʹ(@entry, %made, :@carry);
}

multi sub gen-entryʹ(
    Entry:D @,
    % (
        Coa:D :coa($)!,
        Hodl:D :hodl($)!
    ),
    Entryʹ:D :@carry
    --> Array[Entryʹ:D]
)
{
    # no more C<Entry>s remain to be handled
    my Entryʹ:D @entry = @carry;
}

multi sub gen-entryʹ(
    Entry:D $entry,
    %opts (
        Coa:D :coa($)!,
        Hodl:D :hodl($)!
    )
    --> Entryʹ:D
)
{
    my Entry::Posting:D @posting = $entry.posting;
    my Entry::Postingʹ:D @postingʹ = gen-postingʹ(@posting, %opts);
    my Entryʹ $entryʹ .= new($entry, @postingʹ);
}

# end sub gen-entryʹ }}}
# sub gen-postingʹ {{{

multi sub gen-postingʹ(
    Entry::Posting:D @ (Entry::Posting:D $posting, *@tail),
    %opts (
        Coa:D :coa($)!,
        Hodl:D :hodl($)!
    ),
    Entry::Postingʹ:D :carry(@c)
    --> Array[Entry::Postingʹ:D]
)
{
    my Entry::Posting:D @posting = |@tail;
    my Entry::Postingʹ:D $postingʹ = gen-postingʹ($posting, %opts);
    my Entry::Postingʹ:D @carry = |@c, $postingʹ;
    my %made = $postingʹ.made;
    my Entry::Postingʹ:D @postingʹ = gen-postingʹ(@posting, %made, :@carry);
}

multi sub gen-postingʹ(
    Entry::Posting:D @,
    % (
        Coa:D :coa($)!,
        Hodl:D :hodl($)!
    ),
    Entry::Postingʹ:D :@carry
    --> Array[Entry::Postingʹ:D]
)
{
    my Entry::Postingʹ:D @postingʹ = @carry;
}

multi sub gen-postingʹ(
    Entry::Posting:D $posting,
    %opts (
        Coa:D :coa($)!,
        Hodl:D :hodl($)!
    ),
    --> Entry::Postingʹ:D
)
{
    my Entry::Postingʹ $postingʹ .= new(|%opts);
}

# end sub gen-postingʹ }}}
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

my Entryʹ:D $entryʹ = gen-entryʹ(@entry);
$entryʹ.perl.say;

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
