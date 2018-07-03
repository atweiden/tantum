use v6;
use Tantum::Dx::Coa;
use Tantum::Dx::Entry::Posting;
use Tantum::Dx::Entry;
use Tantum::Dx::Hodl;
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
        Entry:D $e,
        Coa:D $c,
        Hodl:D $h,
        *% (
            Hook:U :@applied,
            Entryʹ:D :@carry
        )
    )
    --> Entryʹ:D
)
{
    my Entry::Posting:D @p = $e.posting;
    my Entry::ID:D $id = $e.id;
    my Entry::Header:D $header = $e.header;
    my Entry::Posting:D @posting = apply(@p, $header);
    my Entry $entry .= new(:$id, :$header, :@posting);
    my Hodl:D $hodl = $*registry.send-to-hooks(HODL, [$h, $entry]);
    my Coa:D $coa = $*registry.send-to-hooks(COA, [$c, $entry, $hodl]);
    my Entryʹ $entryʹ .= new(:$entry, :$coa, :$hodl);
}

multi sub apply(
    Entry::Posting:D @ (Entry::Posting:D $p, *@tail),
    Entry::Header:D $header,
    Entry::Posting:D :carry(@c)
    --> Array[Entry::Posting:D]
)
{
    my Entry::Posting:D @p = |@tail;
    my Entry::Posting:D $posting =
        $*registry.send-to-hooks(POSTING, [$p, $header]);
    my Entry::Posting:D @carry = |@c, $posting;
    my Entry::Posting:D @posting = apply(@p, $header, :@carry);
}

multi sub apply(
    Entry::Posting:D @,
    Entry::Header:D $,
    Entry::Posting:D :@carry
    --> Array[Entry::Posting:D]
)
{
    my Entry::Posting:D @posting = @carry;
}

multi method is-match(
    | (
        Entry:D $entry,
        Coa:D $coa,
        Hodl:D $hodl,
        *% (
            Hook:U :@applied! where .so,
            Entryʹ:D :@carry
        )
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
        Coa:D $coa,
        Hodl:D $hodl,
        *% (
            Hook:U :@applied,
            Entryʹ:D :@carry
        )
    )
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
