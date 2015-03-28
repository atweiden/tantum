use v6;
class Nightscape::Parser::Actions;

method iso_date($/) {
    try {
        make Date.new("$/");
        CATCH { say "Sorry, invalid date"; }
    }
}

method header($/) {
    make %( iso_date => $<iso_date>».made,
            $<description> ?? description => substr($<description>, 1, *-1).trim    # description less surrounding double quotes and whitespace
                           !! description => Nil,                                   # descriptions are optional
            $<comment> ?? eol_comment => substr($<comment>, 1, *-0).trim            # comment less leading pound symbol and surrounding whitespace
                       !! eol_comment => Nil                                        # comments are optional
          );
}

method account($/) {
    make %( account_full => join(':', $<account_main>, $<entity>, $<account_sub>».join(':')),
            account_main => $<account_main>,
            entity => $<entity>,
            $<account_sub> ?? account_sub => $<account_sub>
                           !! account_sub => Nil
          );
}

method transaction($/) {
    make %( commodity_minus => $<commodity_minus>,
            commodity_symbol => $<commodity_symbol>,
            commodity_quantity => $<commodity_quantity>,
            commodity_code => $<commodity_code>,
            exchange_rate => $<exchange_rate>
          );
}

method posting($/) {
    if $<account> && $<transaction> {
        make %( account => $<account>».made,
                transaction => $<transaction>».made,
                $<comment> ?? eol_comment => substr($<comment>, 1, *-0).trim
                           !! eol_comment => Nil
              );
    } else {
        make %( $<comment> ?? posting_comment => substr($<comment>, 1, *-0).trim
                           !! posting_comment => Nil
              );
    }
}

method entry($/) {
    make [
            %( header => $<header>».made,
               posting => [ $<posting>».made ]
             )
         ];
}

method journal($/) {
    if $<entry> {
        make [ %( entry => $<entry>».made ) ];
    } elsif $<comment> {
        make [ %( $<comment> ?? comment_line => substr($<comment>, 1, *-0).trim
                             !! comment_line => Nil ) ];
    } else {
        make [ %( blank_line => True ) ];
    }
}

method TOP($/) {
    make $<journal>».made;
}

# vim: ft=perl6
