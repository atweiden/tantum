use v6;
unit class File::Path::Resolve;

# p6doc {{{

=begin pod
=head NAME

File::Path::Resolve

=head METHODS

=head2 C<absolute($path)>

This method runs C<IO.resolve> on paths to produce absolute path strings
while first making sure to expand a leading C<~/> to C<$*HOME>.

=head2 C<absolute('~/', $path)>

Rakudo considers paths starting with a C<~> to be relative paths:

    '~'.IO.is-relative.so       # True
    '~/'.IO.is-relative.so      # True
    '~/hello'.IO.is-relative.so # True

This method expands the leading C<~> to C<$*HOME>. For now, this is only
done here in cases where the leading C<~> is followed by a C</> for C<~/>.
This is done out of convenience for Tantum, but a more sophisticated
multi dispatch could be used to widen the applicability of this method.

=head2 C<relative($file, $file-base)>

This method is designed for cases where a user may input relative paths
in a config file. In these cases, relative paths should be resolved
relative to the config file's base directory.
=end pod

# end p6doc }}}

# method absolute {{{

multi method absolute(Str:D $path where .so --> Str:D)
{
    my Str:D $resolve = ~File::Path::Resolve.absolute('~/', $path).IO.resolve;
}

multi method absolute('~/', Str:D $path where .so --> Str:D)
{
    my Str:D $subst = sprintf(Q{%s/}, $*HOME);
    my Str:D $resolve = $path.subst(/^'~/'/, $subst);
}

# end method absolute }}}
# method relative {{{

# resolve C<$file> relative to C<$file-base> if C<$file> is relative path
multi method relative(
    Str:D $file where { File::Path::Resolve.absolute('~/', $_).IO.is-relative },
    Str:D $file-base
    --> Str:D
)
{
    my Str:D $relative = join('/', $file-base.IO.dirname, $file);
    my Str:D $resolve = File::Path::Resolve.absolute($relative);
}

multi method relative(
    Str:D $file,
    Str:D $
    --> Str:D
)
{
    my Str:D $resolve = File::Path::Resolve.absolute($file);
}

# end method relative }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
