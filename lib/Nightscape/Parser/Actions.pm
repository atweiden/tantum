use v6;
class Nightscape::Parser::Actions;

my Int $entry_number = 0;

method iso_date($/) {
    try {
        make Date.new("$/");
        CATCH { say "Sorry, invalid date"; }
    }
}

method hashtag($/) {
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
                         $<hashtag> ?? hashtags => [ $<hashtag>».made ]
                                    !! hashtags => Nil,
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
