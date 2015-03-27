use v6;
class Nightscape::Parser::Actions;

method iso_date($/) {
    try {
        make %( iso_date => Date.new("$/") );
        CATCH { say "Sorry, invalid date"; }
    }
}

method header($/) {
    make [ %( header =>
                %( $<iso_date>».made,
                   description => substr($<description>, 1, *-1) # description with surrounding double quotes removed
                 )
            )
         ];
}

method account($/) {
    make [ %( account =>
                %( account_full => join(':', $<account_main>, $<account_sub>».join(':')),
                   account_main => $<account_main>,
                   account_sub => $<account_sub>,
                   entity => $<account_sub>.list[0]
                 )
            )
         ];
}

method transaction($/) {
    make [ %( transaction =>
                %( commodity_minus => $<commodity_minus>,
                   commodity_symbol => $<commodity_symbol>,
                   commodity_quantity => $<commodity_quantity>,
                   commodity_code => $<commodity_code>,
                   exchange_rate => $<exchange_rate>
                 )
            )
         ];
}

method posting($/) {
    make %( $<account>».made,
            $<transaction>».made
          );
}

method entry($/) {
    make %( $<header>».made,
            [ $<posting>».made ]
          );
}

method journal($/) {
    make $<entry>».made;
}

method TOP($/) {
    make $<journal>».made;
}

# vim: ft=perl6
