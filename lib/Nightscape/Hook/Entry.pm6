use v6;
use Nightscape::Dx;
use Nightscape::Registry;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
unit class Nightscape::Hook::Entry;
also does Nightscape::Hook[ENTRY];

has Str:D $!name = 'Entry';
has Str:D $!description = 'catch-all hook for ENTRY';
has Int:D $!priority = 0;
has Nightscape::Hook:U @!dependency;

method name(::?CLASS:D: --> Str:D)
{
    my Str:D $name = $!name;
}

method description(::?CLASS:D: --> Str:D)
{
    my Str:D $description = $!description;
}

method dependency(::?CLASS:D: --> Array[Nightscape::Hook:U])
{
    my Nightscape::Hook:U @dependency = @!dependency;
}

method priority(::?CLASS:D: --> Int:D)
{
    my Int:D $priority = $!priority;
}

multi method apply(
    | (
        Entry:D $e,
        Coa:D $c,
        Hodl:D $h
    )
    --> Entryʹ:D
)
{
    my Entry::Posting:D @p = $entry.posting;
    my Entry::ID:D $id = $entry.id;
    my Entry::Header:D $header = $entry.header;
    # apply POSTING hooks to C<Entry.posting>
    my Entry::Posting:D @posting = apply(@p, $header);
    # instantiate new C<Entry> with new C<@.posting>
    my Entry $entry .= new(:$id, :$header, :@posting);
    # generate new C<Hodl> from C<Entry>
    my Hodl:D $hodl = $registry.send-to-hooks(HODL, [$h, $entry]);
    # generate new C<Coa> from C<Entry>
    my Coa:D $d = $registry.send-to-hooks(COA, [$c, $entry]);
    # make changes to C<Coa> per C<Hodl>
    my Coa:D $coa = apply($d, $hodl);
    # store the result of computations in C<Entryʹ>
    my Entryʹ $entryʹ .= new(:$entry, :$coa, :$hodl);
}

multi method apply(
    | (
        Entryʹ:D $fʹ
    )
    --> Entryʹ:D
)
{
    my Entryʹ:D $entryʹ = $fʹ;
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
        $registry.send-to-hooks(POSTING, [$p, $header]);
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

method is-match(
    Entry:D $entry,
    Coa:D $coa,
    Hodl:D $hodl
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
