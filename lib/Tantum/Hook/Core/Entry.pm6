use v6;
use Tantum::Dx::Entry::Posting;
use Tantum::Dx::Entry;
use Tantum::Hook;
use Tantum::Types;
use TXN::Parser::ParseTree;
unit class Hook::Core::Entry;
also does Hook[ENTRY];

has Str:D $!name = 'Entry';
has Str:D $!description = 'core hook for ENTRY';
has Int:D $!priority = 0;
has Hook:U @!dependency;

method dependency(::?CLASS:D: --> Array[Hook:U])
{
    my Hook:U @dependency = @!dependency;
}

method description(::?CLASS:D: --> Str:D)
{
    my Str:D $description = $!description;
}

method name(::?CLASS:D: --> Str:D)
{
    my Str:D $name = $!name;
}

method priority(::?CLASS:D: --> Int:D)
{
    my Int:D $priority = $!priority;
}

multi method apply(
    | (
        Entry:D $entry,
        Bool:D :$is-entry-balanced! where .so,
        |
    )
)
{
    my Entry::ID:D $id = $entry.id;
    my Entry::Header:D $header = $entry.header;
    my Entry::Posting:D @posting = $entry.posting;
    my Entry::Postingʹ:D @postingʹ = apply(@posting);
    my Entryʹ $entryʹ .= new(:$id, :$header, :@postingʹ);
}

multi sub apply(
    Entry::Posting:D @ (Entry::Posting:D $posting, *@tail),
    Entry::Postingʹ:D :carry(@c)
    --> Array[Entry::Postingʹ:D]
)
{
    my Entry::Posting:D @posting = |@tail;
    my Entry::Postingʹ:D $postingʹ =
        $*registry.send-to-hooks(POSTING, $posting);
    my Entry::Postingʹ:D @carry = |@c, $postingʹ;
    my Entry::Postingʹ:D @postingʹ = apply(@posting, :@carry);
}

multi sub apply(
    Entry::Posting:D @,
    Entry::Postingʹ:D :@carry
    --> Array[Entry::Postingʹ:D]
)
{
    my Entry::Postingʹ:D @postingʹ = @carry;
}

multi method is-match(
    | (
        Entryʹ:D $entryʹ,
        |
    )
    --> Bool:D
)
{
    # don't match if hook has matched/applied previously
    my Bool:D $is-match = False;
}

multi method is-match(
    | (
        Entry:D $entry,
        Bool:D :$is-entry-balanced! where .so,
        |
    )
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

multi method is-match(
    |
    --> Bool:D
)
{
    # don't match by default
    my Bool:D $is-match = False;
}

# vim: set filetype=raku foldmethod=marker foldlevel=0:
