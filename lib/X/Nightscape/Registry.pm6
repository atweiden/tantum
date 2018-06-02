use v6;
use Nightscape::Types;

# X::Nightscape::Registry::NoHookApplied {{{

class X::Nightscape::Registry::NoHookApplied is Exception
{
    has HookType:D $.type is required;

    method message(::?CLASS:D: --> Str:D)
    {
        my Str:D $message =
            sprintf(Q{Sorry, no %s hook applied/carried.}, $.type);
    }
}

# end X::Nightscape::Registry::NoHookApplied }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
