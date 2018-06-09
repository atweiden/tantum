use v6;
use Tantum::Dx::Entry::Posting::Meta;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
unit role Entry::Postingʹ[Silo $silo];
also does Entry::Postingʹ::Meta[$silo];

# C<Entry::Posting> from which C<Entry::Postingʹ> is derived
has Entry::Posting:D $.posting is required;

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
