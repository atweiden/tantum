use v6;
use Nightscape::Config;
class Nightscape::Parser::Actions;

has Nightscape::Config $.conf;

my Int $entry_number = 0;

method iso_date($/) {
    try {
        make Date.new("$/");
        CATCH { say "Sorry, invalid date"; }
    }
}

method tag($/) {
    make substr($/, 1, *-0);
}

method important($/) {
    make $/.chars;
}

method header($/) {
    my $id = $entry_number;
    make %( header => %( id => $id,
                         iso_date => $<iso_date>».made.pairs[0].value,
                         $<description> ?? description => substr($<description>, 1, *-1).trim
                                        !! description => Nil,
                         $<tag> ?? tags => [ $<tag>».made ]
                                !! tags => Nil,
                         $<important> ?? important => $<important>».made.reduce: * + *
                                      !! important => 0,
                         $<comment> ?? eol_comment => substr($<comment>, 1, *-0).trim
                                    !! eol_comment => Nil
                       )
          );
}

method account($/) {
    make %( account => %( account_full => join(':', $<account_main>, $<entity>, $<account_sub>».join(':')).uc,
                          account_main => $<account_main>.uc,
                          entity => $<entity>.uc,
                          $<account_sub> ?? account_sub => [ $<account_sub>.list».uc ]
                                         !! account_sub => Nil
                        )
          );
}

method exchange_rate($/) {
    make %( exchange_rate => %( commodity_symbol => $<commodity_symbol>.uc,
                                commodity_quantity => $<commodity_quantity>.abs,
                                commodity_code => $<commodity_code>.uc
                              )
          );
}

method transaction($/) {
    make %( transaction => %( $<commodity_minus> ?? commodity_minus => True
                                                 !! commodity_minus => False,
                              commodity_symbol => $<commodity_symbol>.uc,
                              commodity_quantity => $<commodity_quantity>.abs,
                              commodity_code => $<commodity_code>.uc,
                              $<exchange_rate> ?? $<exchange_rate>».made
                                               !! exchange_rate => Nil
                            )
          );
}

method posting($/) {
    if $<account> && $<transaction> {

        # say self.conf;
        # my $posting_entity = $<account>».made.hash<account><entity>;
        # my $posting_entity_base_currency = self.conf.entities{$posting_entity}<base-currency>;
        # my $posting_commodity_code = $<transaction>».made.hash<transaction><commodity_code>;
        # my $posting_commodity_quantity = $<transaction>».made.hash<transaction><commodity_quantity>;
        # say $posting_commodity_quantity, " ", $posting_commodity_code, " [", $posting_entity, "]";
        # say $posting_entity_base_currency;

        # if $posting_commodity_code !eq $posting_entity_base_currency {
        #     say "commodity code doesn't match";
        # }

        make %( posting => %( $<account>».made,
                              $<transaction>».made,
                              $<comment> ?? eol_comment => substr($<comment>, 1, *-0).trim
                                         !! eol_comment => Nil
                            )
              );
    } else {
        make %( posting => %( $<comment> ?? posting_comment => substr($<comment>, 1, *-0).trim
                                         !! posting_comment => Nil
                            );
              );
    }
}

method entry($/) {
    make %( $<header>».made,
            postings => [ $<posting>».made».value ]
          );
    $entry_number++;
}

method journal($/) {
    if $<entry> {
        make [ $<entry>».made ];
    } elsif $<comment> {
        make %( comment_line => substr($<comment>, 1, *-0).trim
              );
    } else {
        make %( blank_line => True
              );
    }
}

method TOP($/) {
    make [ $<journal>».made ];
}

# vim: ft=perl6
