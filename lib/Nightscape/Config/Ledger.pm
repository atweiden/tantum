use v6;
use File::Presence;
use Nightscape::Config::Utils;
use Nightscape::Types;
use TXN;
use TXN::Parser;
use TXN::Parser::Types;
use TXN::Remarshal;
use X::Nightscape;

class Nightscape::Config::Ledger::FromFile {...}
class Nightscape::Config::Ledger::FromPkg {...}

# Nightscape::Config::Ledger {{{

class Nightscape::Config::Ledger
{
    # --- method new {{{

    multi method new(
        *%opts (
            Str:D :code($)! where *.so,
            Str:D :file($)! where *.so,
            Int :date-local-offset($),
            Str :txn-dir($)
        )
    )
    {
        Nightscape::Config::Ledger::FromFile.bless(|%opts);
    }

    multi method new(
        *%opts (
            Str:D :pkgname($)! where *.so,
            Str:D :pkgver($)! where *.so,
            Int :pkgrel($)
        )
    )
    {
        Nightscape::Config::Ledger::FromPkg.bless(|%opts);
    }

    multi method new(*%)
    {
        die X::Nightscape::Config::Ledger::Malformed.new;
    }

    # --- end method new }}}
}

# end Nightscape::Config::Ledger }}}
# Nightscape::Config::Ledger::FromFile {{{

class Nightscape::Config::Ledger::FromFile is Nightscape::Config::Ledger
{
    # --- class attributes {{{

    has VarNameBare:D $.code is required;
    has AbsolutePath:D $.file is required;
    has Int $.date-local-offset;
    has AbsolutePath $.txn-dir;

    # --- end class attributes }}}

    # --- submethod BUILD {{{

    submethod BUILD(
        Str:D :$code! where *.so,
        Str:D :$file! where *.so,
        Int :$date-local-offset,
        Str :$txn-dir
    )
    {
        $!code = gen-var-name-bare($code);
        $!file = resolve-path($file);
        $!date-local-offset = $date-local-offset if $date-local-offset.defined;
        $!txn-dir = resolve-path($txn-dir) if $txn-dir;
    }

    # --- end submethod BUILD }}}
    # --- method made {{{

    method made(
        ::?CLASS:D:
        *% (
            Int :$date-local-offset,
            Str :$txn-dir
        )
    ) returns Hash:D
    {
        my VarNameBare:D $pkgname = $.code;
        my Str:D $pkgver = '0.0.1';
        my UInt:D $pkgrel = 1;

        # settings passed as args override class attributes
        my %opts{Str:D};
        %opts<date-local-offset> = $.date-local-offset
            if $.date-local-offset.defined;
        %opts<date-local-offset> = $date-local-offset
            if $date-local-offset.defined;
        %opts<txn-dir> = $.txn-dir if $.txn-dir;
        %opts<txn-dir> = resolve-path($txn-dir) if $txn-dir;

        mktxn(:$.file, :$pkgname, :$pkgver, :$pkgrel, |%opts);
    }

    # --- end method made }}}
}

# end Nightscape::Config::Ledger::FromFile }}}
# Nightscape::Config::Ledger::FromPkg {{{

class Nightscape::Config::Ledger::FromPkg is Nightscape::Config::Ledger
{
    # --- class attributes {{{

    has VarNameBare:D $.pkgname is required;
    has Version:D $.pkgver is required;
    has UInt:D $.pkgrel = 1;

    # --- end class attributes }}}

    # --- submethod BUILD {{{

    submethod BUILD(
        Str:D :$pkgname! where *.so,
        Str:D :$pkgver! where *.so,
        Int :$pkgrel
    )
    {
        $!pkgname = gen-var-name($pkgname);
        $!pkgver = Version.new($pkgver);
        $!pkgrel = $pkgrel if $pkgrel;
    }

    # --- end submethod BUILD }}}
    # --- method made {{{

    method made(::?CLASS:D: AbsolutePath:D :$pkg-dir! where *.so) returns Hash:D
    {
        my AbsolutePath:D $tarball =
            "$pkg-dir/$.pkgname-$.pkgver-$.pkgrel.txn.tar.xz";
        die unless exists-readable-file($tarball);

        # extract tarball to tmpdir
        my AbsolutePath:D $build-root = "$*TMPDIR/$.pkgname-$.pkgver-$.pkgrel";
        $build-root.IO.mkdir or die;
        run qqw<tar -xvf $tarball -C $build-root>;

        my Str:D $txn-json = "$build-root/txn.json".IO.slurp or die;
        my Str:D $txn-info-json = "$build-root/.TXNINFO".IO.slurp or die;

        my TXN::Parser::AST::Entry:D @entry =
            remarshal($txn-json, :if<json>, :of<entry>);
        my %txn-info{Str:D} = Rakudo::Internals::JSON.from-json($txn-info-json);

        # clean up build root
        $build-root.IO.dir».unlink;
        $build-root.IO.rmdir;

        %(:@entry, :%txn-info);
    }

    # --- end method made }}}
}

# end Nightscape::Config::Ledger::FromPkg }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0:
