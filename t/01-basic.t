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
