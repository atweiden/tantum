use v6;
use Tantum::Hook;
use Tantum::Types;
use TXN::Parser::ParseTree;
use X::Tantum::Hook::Core::Entry::Posting;
unit class Hook::Core::Entry::Posting::IsXEPresent;
also does Hook[POSTING];

has Str:D $!name = 'Entry::Posting::IsXEPresent';
has Str:D $!description =
    'ensure config contains proper xe rate for aux assets';
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
    |c (
        Entry::Posting:D $posting,
        |
    )
    --> Capture:D
)
{
    my Bool:D $is-xe-present = apply(|c);
    my Capture:D $apply = \(|c, :$is-xe-present);
}

multi sub apply(
    Entry::Posting:D $posting where { $*config.is-xe-present($_).so },
    |
    --> Bool:D
)
{
    my Bool:D $is-xe-present = True;
}

multi sub apply(
    Entry::Posting:D $posting,
    |
    --> Nil
)
{
    die(X::Tantum::Hook::Core::Entry::Posting::XEMissing.new(:$posting));
}

multi method is-match(
    | (
        Bool:D :$is-xe-present!,
        |
    )
    --> Bool:D
)
{
    # don't match if hook has matched/applied previously
    my Bool:D $is-match = False;
}

multi method is-match(
    | (
        Bool:D :$contains-aux-asset! where .so,
        |
    )
    --> Bool:D
)
{
    # match once we're sure posting contains aux asset
    my Bool:D $is-match = True;
}

multi method is-match(
    |
    --> Bool:D
)
{
    # don't match by default
    my Bool:D $is-match = False;
}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
