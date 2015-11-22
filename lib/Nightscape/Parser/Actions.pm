use v6;
use Digest::xxHash;
use Nightscape::Entry;
use Nightscape::Types;
unit class Nightscape::Parser::Actions;

# DateTime offset for when the local offset is omitted in dates. if
# not passed as a parameter during instantiation, use UTC
has Int $.date_local_offset = 0;

# string grammar-actions {{{

# --- string basic grammar-actions {{{

method string_basic_char:common ($/)
{
    make ~$/;
}

method string_basic_char:tab ($/)
{
    make ~$/;
}

method escape:sym<b>($/)
{
    make "\b";
}

method escape:sym<t>($/)
{
    make "\t";
}

method escape:sym<n>($/)
{
    make "\n";
}

method escape:sym<f>($/)
{
    make "\f";
}

method escape:sym<r>($/)
{
    make "\r";
}

method escape:sym<quote>($/)
{
    make "\"";
}

method escape:sym<backslash>($/)
{
    make '\\';
}

method escape:sym<u>($/)
{
    make chr :16(@<hex>.join);
}

method escape:sym<U>($/)
{
    make chr :16(@<hex>.join);
}

method string_basic_char:escape_sequence ($/)
{
    make $<escape>.made;
}

method string_basic_text($/)
{
    make @<string_basic_char>».made.join;
}

method string_basic($/)
{
    make $<string_basic_text> ?? $<string_basic_text>.made !! "";
}

method string_basic_multiline_char:common ($/)
{
    make ~$/;
}

method string_basic_multiline_char:tab ($/)
{
    make ~$/;
}

method string_basic_multiline_char:newline ($/)
{
    make ~$/;
}

method string_basic_multiline_char:escape_sequence ($/)
{
    if $<escape>
    {
        make $<escape>.made;
    }
    elsif $<ws_remover>
    {
        make "";
    }
}

method string_basic_multiline_text($/)
{
    make @<string_basic_multiline_char>».made.join;
}

method string_basic_multiline($/)
{
    make $<string_basic_multiline_text>
        ?? $<string_basic_multiline_text>.made
        !! "";
}

# --- end string basic grammar-actions }}}
# --- string literal grammar-actions {{{

method string_literal_char:common ($/)
{
    make ~$/;
}

method string_literal_char:backslash ($/)
{
    make '\\';
}

method string_literal_text($/)
{
    make @<string_literal_char>».made.join;
}

method string_literal($/)
{
    make $<string_literal_text> ?? $<string_literal_text>.made !! "";
}

method string_literal_multiline_char:common ($/)
{
    make ~$/;
}

method string_literal_multiline_char:backslash ($/)
{
    make '\\';
}

method string_literal_multiline_text($/)
{
    make @<string_literal_multiline_char>».made.join;
}

method string_literal_multiline($/)
{
    make $<string_literal_multiline_text>
        ?? $<string_literal_multiline_text>.made
        !! "";
}

# --- end string literal grammar-actions }}}

method string:basic ($/)
{
    make $<string_basic>.made;
}

method string:basic_multi ($/)
{
    make $<string_basic_multiline>.made;
}

method string:literal ($/)
{
    make $<string_literal>.made;
}

method string:literal_multi ($/)
{
    make $<string_literal_multiline>.made;
}

# end string grammar-actions }}}
# number grammar-actions {{{

method integer_unsigned($/)
{
    # ensure integers are coerced to type FatRat
    make FatRat(+$/);
}

method float_unsigned($/)
{
    make FatRat(+$/);
}

method plus_or_minus:sym<+>($/)
{
    make ~$/;
}

method plus_or_minus:sym<->($/)
{
    make ~$/;
}

# end number grammar-actions }}}
# datetime grammar-actions {{{

method date_fullyear($/)
{
    make Int(+$/);
}

method date_month($/)
{
    make Int(+$/);
}

method date_mday($/)
{
    make Int(+$/);
}

method time_hour($/)
{
    make Int(+$/);
}

method time_minute($/)
{
    make Int(+$/);
}

method time_second($/)
{
    make Rat(+$/);
}

method time_secfrac($/)
{
    make Rat(+$/);
}

method time_numoffset($/)
{
    my Int $multiplier = $<plus_or_minus> ~~ '+' ?? 1 !! -1;
    make Int(
        (
            ($multiplier * $<time_hour>.made * 60) + $<time_minute>.made
        )
        * 60
    );
}

method time_offset($/)
{
    make $<time_numoffset> ?? Int($<time_numoffset>.made) !! 0;
}

method partial_time($/)
{
    my Rat $second = Rat($<time_second>.made);
    my Bool $subseconds = False;

    if $<time_secfrac>
    {
        $second += Rat($<time_secfrac>.made);
        $subseconds = True;
    }

    make %(
        :hour(Int($<time_hour>.made)),
        :minute(Int($<time_minute>.made)),
        :$second,
        :$subseconds
    );
}

method full_date($/)
{
    make %(
        :year(Int($<date_fullyear>.made)),
        :month(Int($<date_month>.made)),
        :day(Int($<date_mday>.made))
    );
}

method full_time($/)
{
    make %(
        :hour(Int($<partial_time>.made<hour>)),
        :minute(Int($<partial_time>.made<minute>)),
        :second(Rat($<partial_time>.made<second>)),
        :subseconds(Bool($<partial_time>.made<subseconds>)),
        :timezone(Int($<time_offset>.made))
    );
}

method date_time_omit_local_offset($/)
{
    my %fmt;
    %fmt<formatter> =
        {
            # adapted from rakudo/src/core/Temporal.pm
            # needed in place of passing a True :$subseconds arg to
            # the rakudo DateTime default-formatter subroutine
            # for DateTimes with defined time_secfrac
            my $o = .offset;
            $o %% 60
                or warn "DateTime subseconds formatter: offset $o not
                         divisible by 60.";
            my $year = sprintf(
                (0 <= .year <= 9999 ?? '%04d' !! '%+05d'),
                .year
            );
            sprintf '%s-%02d-%02dT%02d:%02d:%s%s',
                $year, .month, .day, .hour, .minute,
                .second.fmt('%09.6f'),
                do $o
                    ?? sprintf '%s%02d:%02d',
                        $o < 0 ?? '-' !! '+',
                        ($o.abs / 60 / 60).floor,
                        ($o.abs / 60 % 60).floor
                    !! 'Z';
        } if $<partial_time>.made<subseconds>;

    make DateTime.new(
        :year(Int($<full_date>.made<year>)),
        :month(Int($<full_date>.made<month>)),
        :day(Int($<full_date>.made<day>)),
        :hour(Int($<partial_time>.made<hour>)),
        :minute(Int($<partial_time>.made<minute>)),
        :second(Rat($<partial_time>.made<second>)),
        :timezone($.date_local_offset),
        |%fmt
    );
}

method date_time($/)
{
    my %fmt;
    %fmt<formatter> =
        {
            # adapted from rakudo/src/core/Temporal.pm
            # needed in place of passing a True :$subseconds arg to
            # the rakudo DateTime default-formatter subroutine
            # for DateTimes with defined time_secfrac
            my $o = .offset;
            $o %% 60
                or warn "DateTime subseconds formatter: offset $o not
                         divisible by 60.";
            my $year = sprintf(
                (0 <= .year <= 9999 ?? '%04d' !! '%+05d'),
                .year
            );
            sprintf '%s-%02d-%02dT%02d:%02d:%s%s',
                $year, .month, .day, .hour, .minute,
                .second.fmt('%09.6f'),
                do $o
                    ?? sprintf '%s%02d:%02d',
                        $o < 0 ?? '-' !! '+',
                        ($o.abs / 60 / 60).floor,
                        ($o.abs / 60 % 60).floor
                    !! 'Z';
        } if $<full_time>.made<subseconds>;

    make DateTime.new(
        :year(Int($<full_date>.made<year>)),
        :month(Int($<full_date>.made<month>)),
        :day(Int($<full_date>.made<day>)),
        :hour(Int($<full_time>.made<hour>)),
        :minute(Int($<full_time>.made<minute>)),
        :second(Rat($<full_time>.made<second>)),
        :timezone(Int($<full_time>.made<timezone>)),
        |%fmt
    );
}

method date:full_date ($/)
{
    make DateTime.new(|$<full_date>.made, :timezone($.date_local_offset));
}

method date:date_time_omit_local_offset ($/)
{
    make $<date_time_omit_local_offset>.made;
}

method date:date_time ($/)
{
    make $<date_time>.made;
}

# end datetime grammar-actions }}}
# variable name grammar-actions {{{

method var_name:bare ($/)
{
    make ~$/;
}

method var_name_string_basic($/)
{
    make $<string_basic_text>.made;
}

method var_name:quoted ($/)
{
    make $<var_name_string_basic>.made;
}

method var_name_string_literal($/)
{
    make $<string_literal_text>.made;
}

# end variable name grammar-actions }}}
# header grammar-actions {{{

method important($/)
{
    # make important the quantity of exclamation marks
    make $/.chars;
}

method tag($/)
{
    # make tag (with leading @ stripped)
    make $<var_name>.made;
}

method meta:important ($/)
{
    make %(important => $<important>.made);
}

method meta:tag ($/)
{
    make %(tag => $<tag>.made);
}

method metainfo($/)
{
    make @<meta>».made;
}

method description($/)
{
    make $<string>.made;
}

method header($/)
{
    # entry date
    my DateTime $date = $<date>.made;

    # entry description
    my Str $description;
    $description = $<description>.made if $<description>;

    # entry importance
    my Int $important = 0;

    # entry tags
    my VarName @tags;

    for @<metainfo>».made -> @metainfo
    {
        $important += [+] @metainfo.grep({ .keys ~~ 'important' })».values.flat;
        push @tags, |@metainfo.grep({ .keys ~~ 'tag' })».values.flat.unique;
    }

    # make entry header container
    make %(:$date, :$description, :$important, :@tags);
}

# end header grammar-actions }}}
# posting grammar-actions {{{

# --- posting account grammar-actions {{{

method acct_name($/)
{
    make @<var_name>».made;
}

method silo:assets ($/)
{
    make ASSETS;
}

method silo:expenses ($/)
{
    make EXPENSES;
}

method silo:income ($/)
{
    make INCOME;
}

method silo:liabilities ($/)
{
    make LIABILITIES;
}

method silo:equity ($/)
{
    make EQUITY;
}

method account($/)
{
    my %account;

    # silo (assets, expenses, income, liabilities, equity)
    %account<silo> = $<silo>.made;

    # entity
    %account<entity> = $<entity>.made;

    # subaccount
    %account<subaccount> = $<account_sub>.made if $<account_sub>;

    # make account
    make Nightscape::Entry::Posting::Account.new(|%account);
}

# --- end posting account grammar-actions }}}
# --- posting amount grammar-actions {{{

method asset_code:bare ($/)
{
    make ~$/;
}

method asset_code:quoted ($/)
{
    make $<var_name_string_basic>.made;
}

method asset_symbol($/)
{
    make ~$/;
}

method asset_quantity:integer ($/)
{
    make $<integer_unsigned>.made;
}

method asset_quantity:float ($/)
{
    make $<float_unsigned>.made;
}

method xe($/)
{
    # asset symbol
    my Str $asset_symbol;
    $asset_symbol = $<asset_symbol>.made if $<asset_symbol>;

    # asset code
    my AssetCode $asset_code = $<asset_code>.made;

    # asset quantity
    my Quantity $asset_quantity = $<asset_quantity>.made;

    # make exchange rate
    make Nightscape::Entry::Posting::Amount::XE.new(
        :$asset_symbol,
        :$asset_code,
        :$asset_quantity
    );
}

method exchange_rate($/)
{
    make $<xe>.made;
}

method amount($/)
{
    # asset symbol
    my Str $asset_symbol;
    $asset_symbol = $<asset_symbol>.made if $<asset_symbol>;

    # asset code
    my AssetCode $asset_code = $<asset_code>.made;

    # asset quantity
    my Quantity $asset_quantity = $<asset_quantity>.made;

    # minus sign
    my Str $plus_or_minus;
    $plus_or_minus = $<plus_or_minus>.made if $<plus_or_minus>;

    # exchange rate
    my Nightscape::Entry::Posting::Amount::XE $exchange_rate;
    $exchange_rate = $<exchange_rate>.made if $<exchange_rate>;

    # make amount
    make Nightscape::Entry::Posting::Amount.new(
        :$asset_code,
        :$asset_quantity,
        :$asset_symbol,
        :$plus_or_minus,
        :$exchange_rate
    );
}

# --- end posting amount grammar-actions }}}

method posting($/)
{
    my Str $text = $/.Str;

    # account
    my Nightscape::Entry::Posting::Account $account = $<account>.made;

    # amount
    my Nightscape::Entry::Posting::Amount $amount = $<amount>.made;

    # dec / inc
    my DecInc $decinc = mkdecinc($amount.plus_or_minus);

    # xxHash of transaction journal posting text
    my xxHash $xxhash = xxHash32($text);

    # make posting container
    make %(:$account, :$amount, :$decinc, :$text, :$xxhash);
}

method posting_line:content ($/)
{
    make $<posting>.made;
}

method postings($/)
{
    make @<posting_line>».made.grep(Hash);
}

# end posting grammar-actions }}}
# include grammar-actions {{{

method filename:basic ($/)
{
    make $<var_name_string_basic>.made;
}

method filename:literal ($/)
{
    make $<var_name_string_literal>.made;
}

method include($/)
{
    # transaction journal to include with .txn extension appended
    my Str $filename = $<filename>.made ~ ".txn";

    # is include directive's transaction journal readable?
    if $filename.IO.e && $filename.IO.r
    {
        # schedule included transaction journal for parsing
        make $filename;
    }
    else
    {
        # exit with an error
        die X::Nightscape::Parser::Include.new(:$filename);
    }
}

method include_line($/)
{
    make $<include>.made;
}

# end include grammar-actions }}}
# journal grammar-actions {{{

method entry($/)
{
    my Str $text = $/.Str;

    # header container
    my %header = $<header>.made;

    # posting containers
    my @postings = $<postings>.made;

    # verify entry is limited to one entity
    {
        my VarName @entities;
        push @entities, $_<account>.entity for @postings;

        # is the number of elements sharing the same entity name not equal
        # to the total number of entity names seen?
        unless @entities.grep(@entities[0]).elems == @entities.elems
        {
            # error: invalid use of more than one entity per journal entry
            die X::Nightscape::Parser::Entry::MultipleEntities.new(
                :number_entities(@entities.elems),
                :entry_text($text)
            );
        }
    }

    # xxHash of transaction journal entry text
    my xxHash $xxhash = xxHash32($text);

    # make entry container
    make %(:%header, :@postings, :$text, :$xxhash);
}

method segment:entry ($/)
{
    make $<entry>.made;
}

method journal($/)
{
    my @entry_containers = @<segment>».made.grep(Hash);

    # increments on each entry (0+)
    my Int $entry_number = 0;

    # instantiate entries
    my Nightscape::Entry @entries;
    for @entry_containers -> %entry
    {
        # instantiate EntryID
        my EntryID $entry_id .= new(
            :number($entry_number++),
            :xxhash(%entry<xxhash>),
            :text(%entry<text>)
        );

        # instantiate entry header
        my Nightscape::Entry::Header $header .= new(|%entry<header>);

        # increments on each posting (0+), resets after each entry
        my Int $posting_number = 0;

        # instantiate entry postings
        my Nightscape::Entry::Posting @postings;
        for %entry<postings> -> @posting_containers
        {
            for @posting_containers -> %posting
            {
                # instantiate PostingID
                my PostingID $posting_id .= new(
                    :$entry_id,
                    :number($posting_number++),
                    :xxhash(%posting<xxhash>),
                    :text(%posting<text>)
                );

                push @postings, Nightscape::Entry::Posting.new(
                    |%posting,
                    :id($posting_id)
                );
            }
        }

        push @entries, Nightscape::Entry.new(
            :id($entry_id),
            :$header,
            :@postings
        );
    }

    make @entries;
}

method TOP($/)
{
    make $<journal>.made;
}

# end journal grammar-actions }}}

# vim: ft=perl6 fdm=marker fdl=0
