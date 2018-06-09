use v6;
use Tantum::Types;

# X::Tantum::Registry::NoHookApplied {{{

class X::Tantum::Registry::NoHookApplied is Exception
{
    has HookType:D $.type is required;

    method new(HookType:D $type --> X::Tantum::Registry::NoHookApplied:D)
    {
        self.bless(:$type);
    }

    method message(::?CLASS:D: --> Str:D)
    {
        my Str:D $message =
            sprintf(Q{Sorry, no %s hook applied/carried}, $.type);
    }
}

# end X::Tantum::Registry::NoHookApplied }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
