use v6;
unit module Tantum::Types;

# p6doc {{{

=begin pod
=head NAME

Tantum::Types

=head DESCRIPTION

=head2 Types of Assets

=begin paragraph
The I<Types of Assets> section pertains to:

=item C<enum AssetConvertibilityType>
=item C<enum AssetPhysicalityType>
=item C<enum AssetUsageType>
=item C<enum AssetType>

What follows is a brief explanation of each.

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

Classifying assets based on their operational usage.
=end item
=end paragraph

=head3 C<AssetConvertibilityType>

=begin paragraph
If assets are classified based on their convertibility into cash, assets
are classified as either current assets (C<CURRENT>) or fixed assets
(C<NON-CURRENT>).
=end paragraph

=head4 C<CURRENT>

=begin paragraph
Current assets are assets that can be easily converted into cash and
cash equivalents (typically within a year). Current assets are also
termed I<liquid assets> and examples of such are:

=item Cash
=item Cash equivalents
=item Short-term deposits
=item Stock
=item Marketable securities
=item Office supplies
=end paragraph

=head4 C<NON-CURRENT>

=begin paragraph
Non-current assets are assets that cannot be easily and readily converted
into cash and cash equivalents. Non-current assets are also termed
I<fixed assets>, I<long-term assets>, or I<hard assets>. Examples of
non-current or fixed assets include:

=item Land
=item Building
=item Machinery
=item Equipment
=item Patents
=item Trademarks
=end paragraph

=head3 C<AssetPhysicalityType>

=begin paragraph
If assets are classified based on their physical existence, assets are
classified as either tangible assets (C<TANGIBLE>) or intangible assets
(C<NON-TANGIBLE>).
=end paragraph

=head4 C<TANGIBLE>

=begin paragraph
Tangible assets are assets that have a physical existence we can touch,
feel, and see. Examples of tangible assets include:

=item Land
=item Building
=item Machinery
=item Equipment
=item Cash
=item Office supplies
=item Stock
=item Marketable securities
=end paragraph

=head4 C<NON-TANGIBLE>

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

=head3 C<AssetUsageType>

=begin paragraph
If assets are classified based on their operational usage, assets are
classified as either operating assets (C<OPERATING>) or non-operating
assets (C<NON-OPERATING>).
=end paragraph

=head4 C<OPERATING>

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

=head4 C<NON-OPERATING>

=begin paragraph
Non-operating assets are assets that are not required for daily business
operations. They can still generate revenue. Examples of non-operating
assets include:

=item Short-term investments
=item Marketable securities
=item Vacant land
=item Interest income from a fixed deposit
=end paragraph

=head3 Current Assets

=head4 Cash and Equivalents (C<CASH-AND-EQUIVALENT>)

=begin paragraph
The most liquid of all assets, cash appears on the first line of the
balance sheet. Cash Equivalents are also lumped under this line item,
and include assets that have short-term maturities under three months or
assets that the company can liquidate on short notice, such as marketable
securities. Companies will generally disclose what equivalents it includes
in the footnotes to the balance sheet.
=end paragraph

=head4 Accounts Receivable (C<RECEIVABLE>)

=begin paragraph
This account includes the balance of all sales revenue still on credit,
net of any allowances for doubtful accounts (which generates a bad debt
expense). As companies recover receivables, Accounts Receivable decreases
and cash increases by the same amount.
=end paragraph

=head4 Inventory (C<INVENTORY>)

=begin paragraph
Inventory includes amounts for raw materials, work-in-progress goods
and finished goods. The company uses this account when it makes sales
of goods, generally under cost of goods sold in the income statement.
=end paragraph

=head3 Non-Current Assets

=head4 Property, Plant and Equipment (C<PROPERTY-PLANT-EQUIPMENT>)

=begin paragraph
Property, Plant and Equipment (also known as PP&E) captures the
company's tangible fixed assets. This line item is noted net
of depreciation. Some companies will class out their PP&E by the
different types of assets, such as Land, Buildings, and various types
of Equipment. All PP&E is depreciable except for Land.
=end paragraph

=head4 Intangible Assets (C<INTANGIBLE>)

=begin paragraph
This line item will include all of the company's intangible fixed assets,
which may or may not be identifiable. Identifiable intangible assets
include patents, licenses, and secret formulas. Unidentifiable intangible
assets include brand and goodwill.
=end paragraph

=head4 Investments (C<INVESTMENT>)

=begin paragraph
This line item will include assets which may not be sold in less than
one year, in addition to assets which are generally illiquid or volatile.
=end paragraph

=head4 Other (C<OTHER>)

=begin paragraph
This line item will include heretofore uncategorized assets.
=end paragraph

=head3 Sources

=item L<"CFI: Types of Assets"|https://corporatefinanceinstitute.com/resources/knowledge/accounting/types-of-assets/>
=item L<"CFI: What is the Balance Sheet?"|https://corporatefinanceinstitute.com/resources/knowledge/accounting/balance-sheet/>
=end pod

# end p6doc }}}

# AbsolutePath {{{

subset AbsolutePath of Str is export where .IO.is-absolute;

# end AbsolutePath }}}
# AssetType {{{

enum AssetConvertibilityType is export <
    CURRENT
    NON-CURRENT
>;

enum AssetPhysicalityType is export <
    TANGIBLE
    NON-TANGIBLE
>;

enum AssetUsageType is export <
    OPERATING
    NON-OPERATING
>;

enum AssetType is export <
    CASH-AND-EQUIVALENT
    INTANGIBLE
    INVENTORY
    INVESTMENT
    OTHER
    PROPERTY-PLANT-EQUIPMENT
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
