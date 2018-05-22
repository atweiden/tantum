use v6;
use Nightscape::Dx;
use Nightscape::Hook;
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

method dependency(::?CLASS:D: --> Array[Nightscape::Hook:U])
{
    my Nightscape::Hook:U @dependency = @!dependency;
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
        Hodl:D $h
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
