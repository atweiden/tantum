use v6;
use Nightscape::Dx;
use Nightscape::Registry;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
unit class Nightscape::Hook::Ledger;
also does Nightscape::Hook[LEDGER];

has Str:D $!name = 'Ledger';
has Str:D $!description = 'catch-all hook for LEDGER';
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
        Ledger:D $ledger,
        Coa:D $c,
        Hodl:D $h
    )
    --> Ledgerʹ:D
)
{
    my Entry:D @entry = $ledger.entry;
    my Entryʹ:D @entryʹ = apply(@entry, $c, $h);
    # last C<Entryʹ> seen has most up-to-date C<Coa> and C<Hodl>
    my Entryʹ:D $entryʹ = @entryʹ.tail;
    my Coa:D $coa = $entryʹ.coa;
    my Hodl:D $hodl = $entryʹ.hodl;
    my Ledgerʹ $ledgerʹ .= new(:$ledger, :@entryʹ, :$coa, :$hodl);
}

# do nothing if passed a C<Ledgerʹ>
multi method apply(
    | (
        Ledgerʹ:D $mʹ
    )
    --> Ledgerʹ:D
)
{
    my Ledgerʹ:D $ledgerʹ = $mʹ;
}

multi sub apply(
    Entry:D @ (Entry:D $entry, *@tail),
    Coa:D $c,
    Hodl:D $h,
    Entryʹ:D :carry(@c)
    --> Array[Entryʹ:D]
)
{
    my Entry:D @entry = |@tail;
    my Entryʹ:D $entryʹ =
        $registry.send-to-hooks(ENTRY, [$entry, $c, $h]);
    my Coa:D $coa = $entryʹ.coa;
    my Hodl:D $hodl = $entryʹ.hodl;
    my Entryʹ:D @carry = |@c, $entryʹ;
    my Entryʹ:D @entryʹ = apply(@entry, $coa, $hodl, :@carry);
}

multi sub apply(
    Entry:D @,
    Coa:D $,
    Hodl:D $,
    Entryʹ:D :@carry
    --> Array[Entryʹ:D]
)
{
    my Entryʹ:D @entryʹ = @carry;
}

method is-match(
    Ledger:D $ledger,
    Coa:D $coa,
    Hodl:D $hodl
    --> Bool:D
)
{
    my Bool:D $is-match = True;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0: