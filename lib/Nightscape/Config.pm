use v6;
class Nightscape::Config;

has Str $.config_file = "%*ENV<HOME>/.config/nightscape/config.toml";
has Str $.data_dir = "%*ENV<HOME>/.nightscape";
has Str $.log_dir = "$!data_dir/logs";
has Str $.currencies_dir = "$!data_dir/currencies";
has %.entities is rw;
has %.currencies is rw;

# filter entities from unvalidated %toml config
method ls_entities(%toml) {
    my Str @entities_found;
    use Nightscape::Parser::Grammar;
    %toml.map({
        if my $parsed_section = Nightscape::Parser::Grammar.parse($_.keys, :rule<account_sub>) {
            push @entities_found, $parsed_section.orig.Str unless Nightscape::Parser::Grammar.parse($parsed_section.orig, :rule<reserved>);
        }
    });

    my %entities_found;
    for @entities_found -> $entity_found {
        %entities_found{$entity_found} = %toml{$entity_found};
    }
    %entities_found;
}

# filter currencies from unvalidated %toml config
method ls_currencies(%toml) {
    my Str $currencies_header;
    %toml.map({ $currencies_header = $/.orig.Str if $_.keys ~~ m:i / ^currencies /; });
    if $currencies_header {
        return %toml{$currencies_header};
    } else {
        return Nil;
    }
}

# vim: ft=perl6
