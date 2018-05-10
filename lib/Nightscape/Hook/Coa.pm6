use v6;
use Nightscape::DX;
use Nightscape::Registry;
unit class Nightscape::Hook::Coa;
also does Nightscape::Hook[COA];

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
    --> Nightscape::Hook::Coa:D
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

method apply(
    Entry::Posting:D $posting,
    Coa:D $c,
    Hodl:D $hodl
    --> Entry::Postingʹ:D
)
{
    my COA:D $coa = $registry.send-to-hooks(COA, [$c, $posting]);
    my Entry::Postingʹ $postingʹ .= new(:$coa, :$hodl, :$posting);
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
