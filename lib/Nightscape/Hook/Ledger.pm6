use v6;
use Nightscape::Dx;
use Nightscape::Hook;
use Nightscape::Types;
use Nightscape::Utils;
use TXN::Parser::ParseTree;
unit class Hook::Ledger;
also does Hook[LEDGER];

has Str:D $!name = 'Ledger';
has Str:D $!description = 'catch-all hook for LEDGER';
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
        Ledger:D $ledger,
        Coa:D $c,
        Hodl:D $h
    )
    --> Ledgerʹ:D
)
{
    my Entry:D @e = $ledger.entry;
    my Entry:D @entry = Nightscape::Utils.ls-entries(@e, :sort);
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
    # XXX type too complex to form :D constraint
    --> Array[Entryʹ]
)
{
    my Entry:D @entry = |@tail;
    my Entryʹ:D $entryʹ = $*registry.send-to-hooks(ENTRY, [$entry, $c, $h]);
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
    # XXX type too complex to form :D constraint
    --> Array[Entryʹ]
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
