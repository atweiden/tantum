use v6;
unit module Tantum::Types;

# AbsolutePath {{{

subset AbsolutePath of Str is export where .IO.is-absolute;

# end AbsolutePath }}}
# AssetType {{{

# --- p6doc {{{

=begin pod
=head Types of Assets

=begin paragraph
Assets are generally classified in three ways:

=begin item
B<Convertibility>

Classifying assets based on how easy it is to convert them into cash.
=end item

=begin item
B<Physicality>

Classifying assets based on their physical existence.
=end item

=begin item
B<Usage>

Classifying assets based on their business operation usage.
=end item
=end paragraph

=item L<"CFI: Types of Assets"|https://corporatefinanceinstitute.com/resources/knowledge/accounting/types-of-assets/>
=end pod

# --- end p6doc }}}

# --- p6doc {{{

=begin pod
=head2 C<AssetConvertibilityType>

=begin paragraph
If assets are classified based on their convertibility into cash, assets
are classified as either current assets (C<CURRENT>) or fixed assets
(C<NON-CURRENT>).
=end paragraph

=head3 C<CURRENT>

=begin paragraph
Current assets are assets that can be easily converted into cash and
cash equivalents (typically within a year). Current assets are also
termed liquid assets and examples of such are:

=item Cash
=item Cash equivalents
=item Short-term deposits
=item Stock
=item Marketable securities
=item Office supplies
=end paragraph

=head3 C<NON-CURRENT>

=begin paragraph
Non-current assets are assets that cannot be easily and readily converted
into cash and cash equivalents. Non-current assets are also termed fixed
assets, long-term assets, or hard assets. Examples of non-current or
fixed assets include:

=item Land
=item Building
=item Machinery
=item Equipment
=item Patents
=item Trademarks
=end paragraph
=end pod

# --- end p6doc }}}

enum AssetConvertibilityType is export <
    CURRENT
    NON-CURRENT
>;

# --- p6doc {{{

=begin pod
=head2 C<AssetPhysicalityType>

=begin paragraph
If assets are classified based on their physical existence, assets are
classified as either tangible assets (C<TANGIBLE>) or intangible assets
(C<NON-TANGIBLE>).
=end paragraph

=head3 C<TANGIBLE>

=begin paragraph
Tangible assets are assets that have a physical existence (we can touch,
feel, and see). Examples of tangible assets include:

=item Land
=item Building
=item Machinery
=item Equipment
=item Cash
=item Office supplies
=item Stock
=item Marketable securities
=end paragraph

=head3 C<NON-TANGIBLE>

=begin paragraph
Intangible assets are assets that do not have a physical
existence. Examples of intangible assets include:

=item Goodwill
=item Patents
=item Brand
=item Copyrights
=item Trademarks
=item Trade secrets
=item Permits
=item Corporate intellectual property
=end paragraph
=end pod

# --- end p6doc }}}

enum AssetPhysicalityType is export <
    TANGIBLE
    NON-TANGIBLE
>;

# --- p6doc {{{

=begin pod
=head2 C<AssetUsageType>

=begin paragraph
If assets are classified based on their operational usage, assets are
classified as either operating assets (C<OPERATING>) or non-operating
assets (C<NON-OPERATING>).
=end paragraph

=head3 C<OPERATING>

=begin paragraph
Operating assets are assets that are required in the daily operation of a
business. In other words, operating assets are used to generate revenue.
Examples of operating assets include:

=item Cash
=item Stock
=item Building
=item Machinery
=item Equipment
=item Patents
=item Copyrights
=item Goodwill
=end paragraph

=head3 C<NON-OPERATING>

=begin paragraph
Non-operating assets are assets that are not required for daily business
operations but can still generate revenue. Examples of non-operating
assets include:

=item Short-term investments
=item Marketable securities
=item Vacant land
=item Interest income from a fixed deposit
=end paragraph
=end pod

# --- end p6doc }}}

enum AssetUsageType is export <
    OPERATING
    NON-OPERATING
>;

# --- p6doc {{{

=begin pod
=head2 Current Assets

=head3 Cash and Equivalents (C<CASH-AND-EQUIVALENT>)

=begin paragraph
The most liquid of all assets, cash appears on the first line of the
balance sheet. Cash Equivalents are also lumped under this line item,
and include assets that have short-term maturities under three months or
assets that the company can liquidate on short notice, such as marketable
securities. Companies will generally disclose what equivalents it includes
in the footnotes to the balance sheet.
=end paragraph

=head3 Accounts Receivable (C<RECEIVABLE>)

=begin paragraph
This account includes the balance of all sales revenue still on credit,
net of any allowances for doubtful accounts (which generates a bad
debt expense). As companies recover accounts receivables, this account
decreases and cash increases by the same amount.
=end paragraph

=head3 Inventory (C<INVENTORY>)

=begin paragraph
Inventory includes amounts for raw materials, work-in-progress goods
and finished goods. The company uses this account when it makes sales
of goods, generally under cost of goods sold in the income statement.
=end paragraph

=head2 Non-Current Assets

=head3 Plant, Property and Equipment (C<PLANT-PROPERTY-EQUIPMENT>)

=begin paragraph
Property, Plant and Equipment (also known as PP&E) captures the
company’s tangible fixed assets. This line item is noted net
of depreciation. Some companies will class out their PP&E by the
different types of assets, such as Land, Building, and various types of
Equipment. All PP&E is depreciable except for Land.
=end paragraph

=head3 Intangible Assets (C<INTANGIBLE>)

=begin paragraph
This line item will include all of the companies intangible fixed assets,
which may or may not be identifiable. Identifiable intangible assets
include patents, licenses, and secret formulas. Unidentifiable intangible
assets include brand and goodwill.
=end paragraph

=head3 Investments (C<INVESTMENT>)

=begin paragraph
This line item will include assets which may not be sold in less than
one year, in addition to assets which are generally illiquid or volatile.
=end paragraph

=head3 Other (C<OTHER>)

=begin paragraph
This line item will include heretofore uncategorized assets.
=end paragraph

=item L<"CFI: What is the Balance Sheet?"|https://corporatefinanceinstitute.com/resources/knowledge/accounting/balance-sheet/>
=end pod

# --- end p6doc }}}

enum AssetType is export <
    CASH-AND-EQUIVALENT
    INTANGIBLE
    INVENTORY
    INVESTMENT
    OTHER
    PLANT-PROPERTY-EQUIPMENT
    RECEIVABLE
>;

# end AssetType }}}
# Costing {{{

enum Costing is export <
    AVCO
    FIFO
    LIFO
>;

# end Costing }}}
# HookType {{{

enum HookType is export <
    POSTING
    ENTRY
    LEDGER
    COA
    HODL
    HOOK
>;

# end HookType }}}
# IncomeType {{{

enum IncomeType is export <
    SALARY-AND-WAGES
    SELF-EMPLOYMENT
    INTEREST
    DIVIDEND
    PASSIVE
    CAPITAL-GAINS
    MISCELLANEOUS
>;

# end IncomeType }}}

# vim: set filetype=perl6 foldmethod=marker foldlevel=0 nowrap:
