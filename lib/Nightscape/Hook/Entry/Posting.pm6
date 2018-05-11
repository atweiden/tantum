use v6;
use Nightscape::Dx;
use Nightscape::Registry;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
unit class Nightscape::Hook::Entry::Posting;
also does Nightscape::Hook[POSTING];

has Str:D $!name = 'Entry::Posting';
has Str:D $!description = 'catch-all hook for POSTING';
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
        Entry::Posting:D $posting,
        Coa:D $c,
        Hodl:D $hodl
    )
    --> Entry::Postingʹ:D
)
{
    my COA:D $coa = $registry.send-to-hooks(COA, [$c, $posting]);
    my Entry::Postingʹ $postingʹ .= new(:$coa, :$hodl, :$posting);
}

# do nothing if passed an C<Entry::Postingʹ>
multi method apply(
    | (
        Entry::Postingʹ:D $qʹ
    )
    --> Entry::Postingʹ:D
)
{
    my Entry::Postingʹ:D $postingʹ = $qʹ;
}

method is-match(
    Entry::Posting:D $posting,
    Coa:D $coa,
    Hodl:D $hodl
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
