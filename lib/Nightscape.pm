use v6;
use Nightscape::Config;
use Nightscape::Journal;
class Nightscape;

has Nightscape::Config $.conf;
has Nightscape::Journal $.journal;

method mkconf(%conf?) {
    $!conf = Nightscape::Config.new(|%conf);
}

method mkjournal($file) {
    use Nightscape::Parser;
    if my $parsed = Nightscape::Parser.parse(slurp($file), self.conf) {
        use Nightscape::Journal::Entry;
        use Nightscape::Journal::Entry::Posting;
        my @entries;
        for $parsed.made.list -> $parse {
            my %header;
            my @postings;
            for $parse.kv -> $key, $value {
                unless $key ~~ / blank_line || comment_line / {
                    if $value.key ~~ /header/ {
                        %header<id> = $value.value<id>;
                        %header<date> = $value.value<iso_date>;
                        %header<description> = $value.value<description>;
                        %header<important> = $value.value<important>.abs;
                        %header<tags> = $value.value<tags>;
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
            }
            push @entries, Nightscape::Journal::Entry.new(|%header, postings => @postings)
            unless $parse.kv.pairs[0].value ~~ / blank_line || comment_line /;
        }
        $!journal = Nightscape::Journal.new( entries => @entries.sort({ $^b.important > $^a.important }).sort({ .date }) );
    }
}

# vim: ft=perl6
