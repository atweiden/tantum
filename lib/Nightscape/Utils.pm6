use v6;
use TXN::Parser::ParseTree;
unit class Nightscape::Utils;

# method ls-entries {{{

method ls-entries(Entry:D @e, Bool :$sort --> Array[Entry:D])
{
    my Entry:D @entry = ls-entries(@e, :$sort);
}

multi sub ls-entries(Entry:D @e, Bool:D :sort($)! where .so --> Array[Entry:D])
{
    # entries, sorted by date ascending then by importance descending
    my Entry:D @entry =
        @e
        .sort({ $^b.header.important > $^a.header.important })
        .sort({ .header.date });
}

multi sub ls-entries(Entry:D @e, Bool :sort($) --> Array[Entry:D])
{
    my Entry:D @entry = @e;
}

# end method ls-entries }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
