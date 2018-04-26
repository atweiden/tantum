use v6;
use File::Path::Resolve;
use File::Presence;
use Nightscape::Config::Utils;
use Nightscape::Types;
use TXN::Parser::ParseTree;
use TXN::Parser::Types;
use TXN::Remarshal;
use TXN;
use X::Nightscape;

# p6doc {{{

=begin pod
=head NAME

C<Nightscape::Config::Ledger>

=head DESCRIPTION

C<Nightscape::Config::Ledger> handles C<[[ledger]]> arraytables declared
in TOML config.

We ascertain the type of ledger declared in each TOML config arraytable
based on the keys provided in the arraytable. These keys are dispatched
against C<multi method new> of class C<Nightscape::Config::Ledger>.

One set of keys will instantiate a
C<Nightscape::Config::Ledger::FromFile>, reflecting the user's desire
to parse TXN from file.

Another set of keys will instantiate a
C<Nightscape::Config::Ledger::FromPkg>, reflecting the user's desire to
use the contents of an existing TXN package.

While it might seem cleaner to use parameterized roles to accomplish
this, taking the object variant approach allows us to C<.map>
against every discovered TOML C<[[ledger]]> arraytable, running
C<Nightscape::Config::Ledger.new> for each one.

If any C<[[ledger]]> arraytable section contains keys which fail to adhere
to the proper format of either C<Nightscape::Config::Ledger::FromFile>
or C<Nightscape::Config::Ledger::FromPkg>, we raise the exception
C<X::Nightscape::Config::Ledger::Malformed>.

Credit: L<https://gist.github.com/zoffixznet/c5d602ee46651613dec964737a0774fa>
=end pod

# end p6doc }}}

class Nightscape::Config::Ledger::FromFile {...}
class Nightscape::Config::Ledger::FromPkg {...}
my role ToHash { method hash() {...} }

# Nightscape::Config::Ledger {{{

class Nightscape::Config::Ledger
{
    multi method new(
        *%opts (
            Str:D :code($)! where .so,
            Str:D :file($)! where .so,
            AbsolutePath:D :scene-file($)! where .so,
            Int :date-local-offset($),
            Str :include-lib($)
        )
        --> Nightscape::Config::Ledger::FromFile:D
    )
    {
        Nightscape::Config::Ledger::FromFile.bless(|%opts);
    }

    multi method new(
        *%opts (
            Str:D :pkgname($)! where .so,
            :pkgver($)! where .defined,
            Int :pkgrel($),
            *%
        )
        --> Nightscape::Config::Ledger::FromPkg:D
    )
    {
        Nightscape::Config::Ledger::FromPkg.bless(|%opts);
    }

    multi method new(*% --> Nil)
    {
        die(X::Nightscape::Config::Ledger::Malformed.new);
    }
}

# end Nightscape::Config::Ledger }}}
# Nightscape::Config::Ledger::FromFile {{{

# --- p6doc {{{

=begin pod
=head NAME

C<Nightscape::Config::Ledger::FromFile>

=head DESCRIPTION

Class attributes store values from parsed TOML config.

=head METHODS

=head2 C<made>

Takes optional C<Int :$date-local-offset, Str :$include-lib>, which are
passed as args from Nightscape cmdline. Any args passed from Nightscape
cmdline which conflict with C<Nightscape::Config::Ledger::FromFile>
class attributes override the class attributes.

For example, C<$date-local-offset> if passed, overrides
C<$.date-local-offset>. Similarly, C<$include-lib> if passed, overrides
C<$.include-lib>.
=end pod

# --- end p6doc }}}

class Nightscape::Config::Ledger::FromFile
{
    also is Nightscape::Config::Ledger;
    also does ToHash;

    has VarNameBare:D $.code is required;
    has AbsolutePath:D $.file is required;
    has Int $.date-local-offset;
    has AbsolutePath $.include-lib;

    submethod BUILD(
        Str:D :$code! where .so,
        Str:D :$file! where .so,
        AbsolutePath:D :$scene-file! where .so,
        Int :$date-local-offset,
        Str :$include-lib
        --> Nil
    )
    {
        $!code = gen-var-name-bare($code);
        $!file = File::Path::Resolve.relative($file, $scene-file);
        $!date-local-offset = $date-local-offset if $date-local-offset.defined;
        $!include-lib =
            File::Path::Resolve.relative($include-lib, $scene-file)
                if $include-lib;
    }

    method new(
        *%opts (
            Str:D :code($)! where .so,
            Str:D :file($)! where .so,
            AbsolutePath:D :scene-file($) where .so,
            Int :date-local-offset($),
            Str :include-lib($)
        )
        --> Nil
    )
    {
        self.bless(|%opts);
    }

    method hash(::?CLASS:D: --> Hash:D)
    {
        my %hash;
        %hash<code> = $.code;
        %hash<file> = $.file;
        %hash<date-local-offset> = $.date-local-offset if $.date-local-offset;
        %hash<include-lib> = $.include-lib if $.include-lib;
        %hash;
    }

    method made(
        ::?CLASS:D:
        *% (
            Int :$date-local-offset,
            Str :$include-lib
        )
        --> Hash:D
    )
    {
        exists-readable-file($.file)
            or die(X::Nightscape::Config::Ledger::FromFile::DNERF.new);
        my VarNameBare:D $pkgname = $.code;
        my Version $pkgver .= new('0.0.1');
        my UInt:D $pkgrel = 1;
        # settings passed as args from Nightscape cmdline override class
        # attributes gleaned from parsing TOML
        my %opts{Str:D};
        %opts<date-local-offset> = $.date-local-offset
            if $.date-local-offset.defined;
        %opts<date-local-offset> = $date-local-offset
            if $date-local-offset.defined;
        %opts<include-lib> = $.include-lib
            if $.include-lib;
        %opts<include-lib> = File::Path::Resolve.absolute($include-lib)
            if $include-lib;
        my %made =
            mktxn(:$pkgname, :$pkgver, :$pkgrel, :source($.file), |%opts);
    }
}

# end Nightscape::Config::Ledger::FromFile }}}
# Nightscape::Config::Ledger::FromPkg {{{

class Nightscape::Config::Ledger::FromPkg
{
    also is Nightscape::Config::Ledger;
    also does ToHash;

    has VarNameBare:D $.pkgname is required;
    has Version:D $.pkgver is required;
    has UInt:D $.pkgrel = 1;

    submethod BUILD(
        Str:D :$pkgname! where .so,
        :$pkgver! where .defined,
        Int :$pkgrel
        --> Nil
    )
    {
        $!pkgname = gen-var-name($pkgname);
        $!pkgver = Version.new($pkgver);
        $!pkgrel = $pkgrel if $pkgrel;
    }

    method hash(::?CLASS:D: --> Hash:D)
    {
        my %hash;
        %hash<pkgname> = $.pkgname;
        %hash<pkgver> = $.pkgver;
        %hash<pkgrel> = $.pkgrel;
        %hash;
    }

    method made(::?CLASS:D: AbsolutePath:D :$pkg-dir! where .so --> Hash:D)
    {
        my AbsolutePath:D $build-root =
            sprintf(Q{%s/%s-%s-%s}, $*TMPDIR, $.pkgname, $.pkgver, $.pkgrel);
        made('extract', $pkg-dir, $build-root, $.pkgname, $.pkgver, $.pkgrel);
        my Str:D $txn-json = made('slurp', 'txn.json', $build-root);
        my Str:D $txn-info-json = made('slurp', '.TXNINFO', $build-root);
        my Entry:D @entry = remarshal($txn-json, :if<json>, :of<entry>);
        my %txn-info{Str:D} = Rakudo::Internals::JSON.from-json($txn-info-json);
        made('clean', $build-root);
        my %made = :@entry, :%txn-info;
    }

    multi sub made(
        'extract',
        AbsolutePath:D $pkg-dir,
        AbsolutePath:D $build-root,
        VarNameBare:D $pkgname,
        Version:D $pkgver,
        UInt:D $pkgrel
        --> Nil
    )
    {
        # extract tarball to tmpdir
        my Str:D $txn-pkg-file =
            TXN.gen-txn-pkg-file($pkgname, $pkgver, $pkgrel);
        my AbsolutePath:D $tarball = sprintf(Q{%s/%s}, $pkg-dir, $txn-pkg-file);
        exists-readable-file($tarball)
            or die(X::Nightscape::Config::Ledger::FromPkg::DNERF.new);
        mkdir($build-root) or do {
            my Str:D $text =
                'Could not create tmpdir build root for ledger pkg tarball';
            die(X::Nightscape::Config::Mkdir::Failed.new(:$text));
        }
        my Str:D $tar-cmdline =
            sprintf(Q{tar -xvf %s -C %s}, $tarball, $build-root);
        run($tar-cmdline);
    }

    multi sub made(
        'slurp',
        'txn.json',
        AbsolutePath:D $build-root
        --> Str:D
    )
    {
        # ensure txn.json exists in ledger pkg tarball then slurp
        my AbsolutePath:D $txn-json-path = sprintf(Q{%s/txn.json}, $build-root);
        exists-readable-file($txn-json-path)
            or die(X::Nightscape::Config::Ledger::FromPkg::TXNJSON::DNERF.new);
        my Str:D $txn-json = slurp($txn-json-path);
    }

    multi sub made(
        'slurp',
        '.TXNINFO',
        AbsolutePath:D $build-root
        --> Str:D
    )
    {
        # ensure .TXNINFO exists in ledger pkg tarball then slurp
        my AbsolutePath:D $txn-info-json-path =
            sprintf(Q{%s/.TXNINFO}, $build-root);
        exists-readable-file($txn-info-json-path)
            or die(X::Nightscape::Config::Ledger::FromPkg::TXNINFO::DNERF.new);
        my Str:D $txn-info-json = slurp($txn-info-json-path);
    }

    multi sub made(
        'clean',
        AbsolutePath:D $build-root
        --> Nil
    )
    {
        # clean up build root
        dir($build-root).hyper.map({ .unlink });
        rmdir($build-root);
    }
}

# end Nightscape::Config::Ledger::FromPkg }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
