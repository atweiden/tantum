use v6;
use lib 'lib';
use Test;
use Nightscape::Parser::Grammar;

plan 3;

# date grammar tests {{{

# end date grammar tests }}}
# metainfo grammar tests {{{

subtest
{
    my Str @metainfo =
        Q{@tag1 ! @TAG2 !! @TAG5 @bliss !!!!!},
        Q{@"∅" !! @96 !!!!};
    my Str $metainfo_multiline = Q:to/EOF/;
    !!!# comment
    @tag1 # comment
    # comment
    @tag2 # comment
    # another comment
    @tag3#comment
    !!!!!
    EOF
    push @metainfo, $metainfo_multiline.trim;

    sub is_valid_metainfo(Str:D $metainfo) returns Bool:D
    {
        Nightscape::Parser::Grammar.parse($metainfo, :rule<metainfo>).so;
    }

    ok(
        @metainfo.grep({is_valid_metainfo($_)}).elems == @metainfo.elems,
        q:to/EOF/
        ♪ [Grammar.parse($metainfo, :rule<metainfo>)] - 1 of X
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Metainfo validates successfully, as expected.
        ┃   Success   ┃
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

# end metainfo grammar tests }}}
# description grammar tests {{{

subtest
{
    my Str @descriptions =
        Q{"Transaction\tDescription"},
        Q{"""Transaction\nDescription"""},
        Q{'Transaction Description\'};
        Q{'''Transaction Description\'''};
    my Str $description_multiline = Q:to/EOF/;
    """
    Multiline description line one. \
    Multiline description line two.
    """
    EOF
    push @descriptions, $description_multiline.trim;

    sub is_valid_description(Str:D $description) returns Bool:D
    {
        Nightscape::Parser::Grammar.parse($description, :rule<description>).so;
    }

    ok(
        @descriptions.grep({is_valid_description($_)}).elems ==
            @descriptions.elems,
        q:to/EOF/
        ♪ [Grammar.parse($description, :rule<description>)] - 1 of X
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Descriptions validates successfully, as expected.
        ┃   Success   ┃
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

# end description grammar tests }}}
# header grammar tests {{{

subtest
{
    my Str @headers;

    push @headers, Q{2014-01-01 "I started with $1000" ! @TAG1 @TAG2 # COMMENT};

    push @headers, Q{2014-01-02 "I paid Exxon Mobile $10"};

    push @headers, Q{2014-01-02};

    push @headers, Q{2014-01-03 "I bought ฿0.80000000 BTC for $800#@*!\\%$"};

    my Str $header_multiline = Q:to/EOF/;
    2014-05-09# comment
    # comment
    @tag1 @tag2 @tag3 !!!# comment
    # comment
    """ # non-comment
    This is a multiline description of the transaction.
    This is another line of the multiline description.
    """# comment
    #comment
    @tag4#comment
    #comment
    @tag5#comment
    @tag6#comment
    #comment
    !!!# comment here
    EOF
    push @headers, $header_multiline;

    say '[DEBUG] ', Nightscape::Parser::Grammar.parse(
        $header_multiline,
        :rule<header>
    );

    sub is_valid_header(Str:D $header) returns Bool:D
    {
        Nightscape::Parser::Grammar.parse($header, :rule<header>).so;
    }

    ok(
        @headers.grep({is_valid_header($_)}).elems == @headers.elems,
        q:to/EOF/
        ♪ [Grammar.parse($header, :rule<header>)] - 1 of X
        ┏━━━━━━━━━━━━━┓
        ┃             ┃  ∙ Headers validate successfully, as expected.
        ┃   Success   ┃
        ┃             ┃
        ┗━━━━━━━━━━━━━┛
        EOF
    );
}

# end header grammar tests }}}

# vim: ft=perl6 fdm=marker fdl=0
