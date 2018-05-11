use v6;
use Nightscape::Dx;
use Nightscape::Registry;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
unit class Nightscape::Hook::Entry;
also does Nightscape::Hook[ENTRY];

has Str:D $!name is required;
has Str:D $!description is required;
has Int:D $!priority = 0;
has Nightscape::Hook:U @!dependency;

submethod BUILD(
    Str:D :$!name!,
    Str:D :$!description!,
    Int:D :$priority,
    Nightscape::Hook:U :@dependency
    --> Nil
)
{
    $!priority = |$priority if $priority;
    @!dependency = |@dependency if @dependency;
}

method new(
    *%opts (
        Str:D :name($)!,
        Str:D :description($)!,
        Int:D :priority($),
        Nightscape::Hook:U :dependency(@)
    )
    --> Nightscape::Hook::Entry::Posting:D
)
{
    self.bless(|%opts);
}

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
    |c (
        Entry:D $entry,
        Coa:D $c,
        Hodl:D $h
    )
    --> Entryʹ:D
)
{
    my Entry::Posting:D @posting = $entry.posting;
    my Entry::Postingʹ:D @postingʹ = apply(@posting, $c, $h);
    # last C<Entry::Postingʹ> seen has most up-to-date C<Coa> and C<Hodl>
    my Entry::Postingʹ:D $postingʹ = @postingʹ.tail;
    my Coa:D $coa = $postingʹ.coa;
    my Hodl:D $hodl = $postingʹ.hodl;
    my Entryʹ $entryʹ .= new(:$entry, :@postingʹ, :$coa, :$hodl);
}

# do nothing if passed an C<Entryʹ>
multi method apply(
    |c (
        Entryʹ:D $fʹ
    )
    --> Entryʹ:D
)
{
    my Entryʹ:D $entryʹ = $fʹ;
}

multi sub apply(
    Entry::Posting:D @ (Entry::Posting:D $posting, *@tail),
    Coa:D $c,
    Hodl:D $h,
    Entry::Postingʹ:D :carry(@c)
    --> Array[Entry::Postingʹ:D]
)
{
    my Entry::Posting:D @posting = |@tail;
    my Entry::Postingʹ:D $postingʹ =
        $registry.send-to-hooks(POSTING, [$posting, $c, $h]);
    my Coa:D $coa = $postingʹ.coa;
    my Hodl:D $hodl = $postingʹ.hodl;
    my Entry::Postingʹ:D @carry = |@c, $postingʹ;
    my Entry::Postingʹ:D @postingʹ = apply(@posting, $coa, $hodl, :@carry);
}

multi sub apply(
    Entry::Posting:D @,
    Coa:D $,
    Hodl:D $,
    Entry::Postingʹ:D :@carry
    --> Array[Entry::Postingʹ:D]
)
{
    my Entry::Postingʹ:D @postingʹ = @carry;
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
