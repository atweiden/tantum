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
            $<description> ?? description => substr($<description>, 1, *-1)    # description with surrounding double quotes removed
                           !! description => Nil,                              # descriptions are optional
            eol_comment => $<comment>
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
                eol_comment => $<comment>
              );
    } else {
        make %( posting_comment => $<comment> );
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
        make [ %( comment_line => $<comment> ) ];
    } else {
        make [ %( blank_line => True ) ];
    }
}

method TOP($/) {
    make $<journal>».made;
}

# vim: ft=perl6
