use v6;
use Nightscape::Parser;
class Nightscape;

method it($file) {
    say q:to/EOF/;
    Diagnostics
    ===========

    Config
    ------
    EOF
    say "Hash: ", %Config::CONFIG.perl;
    say "";
    my $content = slurp $file;
    if my $parsed = Nightscape::Parser.parse($content) {
        use Nightscape::Journal::Entry;
        use Nightscape::Journal::Entry::Posting;
        my @entries;
        say q:to/EOF/;
        Entries
        -------
        EOF
        for $parsed.made.list -> $journal {
            my %header;
            my @postings;
            for $journal.kv -> $key, $value {
                # build Entry class
                unless $key ~~ / blank_line || comment_line / {
                    if $value.key ~~ /header/ {
                        %header<date> = $value.value<iso_date>;
                        %header<description> = $value.value<description>;
                        %header<tags> = $value.value<hashtags>;
                    } elsif $value.key ~~ /postings/ {
                        loop (my $i = 0; $i < $value.value.elems; $i++) {
                            unless $value.value[$i]<posting_comment> {
                                if $value.value[$i]<account><account_main> {
                                    my %posting;
                                    %posting<silo> = Nightscape::Journal::Entry::Posting.mksilo: $value.value[$i]<account><account_main>;
                                    %posting<drcr> = Nightscape::Journal::Entry::Posting.mkdrcr: $value.value[$i]<transaction><commodity_minus>;
                                    %posting<entity> = $value.value[$i]<account><entity>;
                                    %posting<subaccount> = $value.value[$i]<account><account_sub>;
                                    %posting<amounts> = %(
                                        commodity_code => $value.value[$i]<transaction><commodity_code>,
                                        commodity_quantity => $value.value[$i]<transaction><commodity_quantity>,
                                        $value.value[$i]<transaction><exchange_rate>
                                        ?? exchange_rate => %(
                                            commodity_code => $value.value[$i]<transaction><exchange_rate><commodity_code>,
                                            commodity_quantity => $value.value[$i]<transaction><exchange_rate><commodity_quantity>
                                        )
                                        !! exchange_rate => Nil
                                    );
                                    push @postings, Nightscape::Journal::Entry::Posting.new(|%posting);
                                }
                            }
                        }
                    }
                }

                # output
                unless $key ~~ / blank_line || comment_line / {
                    if $value.key ~~ /header/ {
                        print $value.value<iso_date>;
                        if $value.value<description> {
                            print " \"", $value.value<description>, "\"";
                        }
                        if $value.value<hashtags> {
                            print " ";
                            for $value.value<hashtags>».lc -> $hashtag {
                                print "#", $hashtag, " ";
                            }
                        }
                        say "";
                    } elsif $value.key ~~ /postings/ {
                        loop (my $i = 0; $i < $value.value.elems; $i++) {
                            unless $value.value[$i]<posting_comment> {
                                print "  ",
                                    $value.value[$i]<account><account_main>.lc.tc,
                                    ":",
                                    $value.value[$i]<account><entity>.lc.tc;
                                print ":",
                                    $value.value[$i]<account><account_sub>».lc».tc.join(':')
                                    if $value.value[$i]<account><account_sub>;
                                print "\t" x 2,
                                    $value.value[$i]<transaction><commodity_code>, " ",
                                    $value.value[$i]<transaction><commodity_minus> ?? "-" !! "",
                                    $value.value[$i]<transaction><commodity_quantity>;
                                print " @ ",
                                    $value.value[$i]<transaction><exchange_rate><commodity_code>,
                                    " ",
                                    $value.value[$i]<transaction><exchange_rate><commodity_quantity>
                                    if $value.value[$i]<transaction><exchange_rate>;
                                say "";
                            }
                        }
                    }
                    say "" if $key;
                }
            }

            push @entries, Nightscape::Journal::Entry.new(|%header, postings => @postings)
            unless $journal.kv.pairs[0].value ~~ / blank_line || comment_line /;
        };
        say q:to/EOF/;
        Data
        ----
        EOF
        say @entries.sort({ .date }).perl;
    }
}

# vim: ft=perl6
