use v6;
use Nightscape::Entry;
use Nightscape::Types;
use UUID;
unit class Nightscape::Parser::Actions;

# increments on each newly found transaction journal entry (0+)
my Int $entry_number = 0;

# created first in Entry::Header, referenced by Entry::Posting (parent-child)
my UUID $entry_uuid;

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
    # ensure integers are coerced to type Rat
    make Rat(+$/);
}

method float_unsigned($/)
{
    make Rat(+$/);
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

method iso_date:full_date ($/)
{
    make DateTime.new(|$<full_date>.made);
}

method iso_date:date_time ($/)
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
    # entry id
    my Int $id = $entry_number;

    # entry uuid
    my UUID $uuid = UUID.new;
    $entry_uuid = $uuid;

    # entry date
    my DateTime $date = $<iso_date>.made;

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

    # make entry header
    make Nightscape::Entry::Header.new(
        :$id,
        :$uuid,
        :$date,
        :$description,
        :$important,
        :@tags
    );
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
    # silo (assets, expenses, income, liabilities, equity)
    my Silo $silo = $<silo>.made;

    # entity
    my VarName $entity = $<entity>.made;

    # subaccount
    my VarName @subaccount = @<account_sub>».made // Nil;

    # make account
    make Nightscape::Entry::Posting::Account.new(
        :$silo,
        :$entity,
        :@subaccount
    );
}

# --- end posting account grammar-actions }}}
# --- posting amount grammar-actions {{{

method asset_code($/)
{
    make ~$/;
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
    my Str $minus_sign;
    $minus_sign = $<plus_or_minus>.made if $<plus_or_minus>.made ~~ '-';

    # exchange rate
    my Nightscape::Entry::Posting::Amount::XE $exchange_rate;
    $exchange_rate = $<exchange_rate>.made if $<exchange_rate>;

    # make amount
    make Nightscape::Entry::Posting::Amount.new(
        :$asset_code,
        :$asset_quantity,
        :$asset_symbol,
        :$minus_sign,
        :$exchange_rate
    );
}

# --- end posting amount grammar-actions }}}

method posting($/)
{
    # posting uuid
    my UUID $posting_uuid = UUID.new;

    # account
    my Nightscape::Entry::Posting::Account $account = $<account>.made;

    # amount
    my Nightscape::Entry::Posting::Amount $amount = $<amount>.made;

    # dec / inc
    my DecInc $decinc = Nightscape::Types.mkdecinc: $amount.minus_sign.Bool;

    # make posting
    make Nightscape::Entry::Posting.new(
        :$entry_uuid,
        :$posting_uuid,
        :$account,
        :$amount,
        :$decinc
    );
}

method posting_line:content ($/)
{
    make $<posting>.made;
}

method postings($/)
{
    make @<posting_line>».made.grep(Nightscape::Entry::Posting);
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
    # transaction journal to include with .transactions extension appended
    my Str $filename = $<filename>.made ~ ".transactions";

    # is include directive's transaction journal readable?
    if $filename.IO.e && $filename.IO.r
    {
        # schedule included transaction journal for parsing
        make $filename;
    }
    else
    {
        # exit with an error
        die qq:to/EOF/;
        Sorry, could not load transaction journal to include at

            「$filename」

        Transaction journal not found or not readable.
        EOF
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
    # header
    my Nightscape::Entry::Header $header = $<header>.made;

    # postings
    my Nightscape::Entry::Posting @postings = $<postings>.made;

    # verify entry is limited to one entity
    my VarName @entities;
    push @entities, $_.account.entity for @postings;

    # is the number of elements sharing the same entity name not equal
    # to the total number of entity names seen?
    unless @entities.grep(@entities[0]).elems == @entities.elems
    {
        # error: invalid use of more than one entity per journal entry
        die "Sorry, only one entity per journal entry allowed, but found: ",
            @entities.perl, " in entry with header: ", $header.perl;
    }

    # make entry
    make Nightscape::Entry.new(:$header, :@postings);

    # increment entry id number
    $entry_number++;
}

method segment:entry ($/)
{
    make $<entry>.made;
}

method journal($/)
{
    make @<segment>».made;
}

method TOP($/)
{
    make $<journal>.made;
}

# end journal grammar-actions }}}

# vim: ft=perl6 fdm=marker fdl=0
