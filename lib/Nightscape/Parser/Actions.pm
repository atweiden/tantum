use v6;
use Nightscape::Config;
class Nightscape::Parser::Actions;

has Nightscape::Config $.conf;

my Int $entry_number = 0;
my Date $entry_date;

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
    $entry_date = $<iso_date>».made.pairs[0].value;
    make %( header => %( id => $id,
                         iso_date => $entry_date,
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
    make %( account => %( account_full => join(':', $<account_main>, $<entity>, $<account_sub>».join(':')).Str,
                          account_main => $<account_main>.Str,
                          entity => $<entity>.Str,
                          $<account_sub> ?? account_sub => [ $<account_sub>.list».Str ]
                                         !! account_sub => Nil
                        )
          );
}

method exchange_rate($/) {
    make %( exchange_rate => %( commodity_symbol => $<commodity_symbol>.Str,
                                commodity_quantity => $<commodity_quantity>.abs,
                                commodity_code => $<commodity_code>.Str
                              )
          );
}

method transaction($/) {
    make %( transaction => %( $<commodity_minus> ?? commodity_minus => True
                                                 !! commodity_minus => False,
                              commodity_symbol => $<commodity_symbol>.Str,
                              commodity_quantity => $<commodity_quantity>.abs,
                              commodity_code => $<commodity_code>.Str,
                              $<exchange_rate> ?? $<exchange_rate>».made
                                               !! exchange_rate => Nil
                            )
          );
}

method posting($/) {
    if $<account> && $<transaction> {

        my $posting_entity = $<account>».made.hash<account><entity>;
        my $posting_entity_base_currency = self.conf.get_base_currency($posting_entity);
        my $posting_commodity_code = $<transaction>».made.hash<transaction><commodity_code>;
        my $posting_commodity_quantity = $<transaction>».made.hash<transaction><commodity_quantity>;
        my $posting_value;

        # search for exchange rate if posting commodity code differs from entity's base-currency
        if $posting_commodity_code !eq $posting_entity_base_currency {
            if my $exchange_rate = $<transaction>».made.hash<transaction><exchange_rate> {
                # calculating posting value in base currency based on exchange rate given in transaction journal
                if $exchange_rate<commodity_code> eq $posting_entity_base_currency {
                    $posting_value = $posting_commodity_quantity * $exchange_rate<commodity_quantity>;
                } else {
                    # error: exchange rate given in transaction journal doesn't match the posting entity's base-currency
                    my $xecc = $exchange_rate<commodity_code>;
                    my $help_text_faulty_exchange_rate = qq:to/EOF/;
                    Sorry, exchange rate detected in transaction journal doesn't
                    match the parsed entity's base-currency:

                        entity: 「$posting_entity」
                        base-currency: 「$posting_entity_base_currency」
                        exchange rate currency code given in journal: 「$xecc」

                    To debug, verify that the entity has been configured with the
                    correct base-currency. Then verify the transaction journal
                    gives a matching base-currency code for entry number
                    $entry_number.
                    EOF
                    die $help_text_faulty_exchange_rate.trim;
                }
            } elsif my $price = self.conf.getprice(
                aux => $posting_commodity_code,
                base => $posting_entity_base_currency,
                date => $entry_date) {
                # calculating posting value in base currency based on exchange rate given in config file
                $posting_value = $posting_commodity_quantity * $price;
            } else {
                # error: missing exchange rate
                my $help_text_faulty_exchange_rate_in_config_file = qq:to/EOF/;
                Sorry, exchange rate missing for posting in transaction
                journal.

                The transaction journal does not offer an exchange rate
                with @ syntax, and the config file does not offer an
                exchange rate for the posting entity's base-currency on
                the date of the posting:

                        date: 「$entry_date」
                        entity: 「$posting_entity」
                        base-currency: 「$posting_entity_base_currency」
                        currency code given in journal: 「$posting_commodity_code」

                To debug, confirm that the data for price pair $posting_entity_base_currency/$posting_commodity_code
                on $entry_date was entered accurately for entry number
                $entry_number. Verify that the entity has been configured
                with the correct base-currency.
                EOF
                die $help_text_faulty_exchange_rate_in_config_file.trim;
            }
        }

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
