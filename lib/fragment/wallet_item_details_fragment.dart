import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

/// Displays a wallet item summary and its monthly transactions.
class WalletItemDetailsFragment<T extends WalletItem> extends ConsumerWidget {
  const WalletItemDetailsFragment({
    super.key,
    required this.item,
    required this.content,
    required this.transactions,
    required this.month,
    required this.onMonthChanged,
    required this.onSortButtonPressed,
    required this.onRefreshButtonPressed,
    this.headerActions,
    this.isReverse = false,
    this.sortByCalculatedDate = false,
  });

  /// Account or payment being displayed.
  final T item;

  /// Balance or aggregate amount shown in the header.
  final Decimal content;

  /// Optional actions displayed between the wallet summary and filters.
  final Widget? headerActions;

  /// Called when the displayed month changes.
  final void Function(DateTime) onMonthChanged;

  /// Called when transaction ordering is toggled.
  final void Function() onSortButtonPressed;

  /// Called when a data refresh is requested.
  final Future<void> Function() onRefreshButtonPressed;

  /// Transactions for the selected wallet item and month.
  final List<Transaction> transactions;

  /// Month currently displayed.
  final DateTime month;

  /// Whether transaction ordering is reversed.
  final bool isReverse;

  /// Whether transactions are grouped by calculated date.
  final bool sortByCalculatedDate;

  /// Formats a group label for [date] relative to [month].
  String buildGroupSeparator(DateTime date) {
    if (month.year != date.year) {
      return DateFormat.yMd().format(date);
    } else if (month.month != date.month) {
      return DateFormat.Md().format(date);
    }
    return DateFormat.d().format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = provider.getCurrency(ref, item.currencyId);
    const height = 100.0;
    return RefreshIndicator(
      onRefresh: onRefreshButtonPressed,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            floating: true,
            snap: true,
            pinned: false,
            stretch: true,
            bottom: PreferredSize(
              preferredSize: Size(MediaQuery.of(context).size.width, height),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectableText(
                      item.serialNumber,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.swatches.contentSecondary,
                          ),
                    ),
                    SelectableText(
                      currency.format(content),
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      item.descriptions,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.swatches.contentSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (headerActions != null)
            SliverToBoxAdapter(
              child: headerActions!,
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: Icon(isReverse
                        ? Icons.arrow_upward_outlined
                        : Icons.arrow_downward),
                    onPressed: onSortButtonPressed,
                    label: Text(LocaleKeys.sort.tr()),
                  ),
                  MonthPicker(
                    date: month,
                    onDateChanged: onMonthChanged,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefreshButtonPressed,
                    label: Text(LocaleKeys.refresh.tr()),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: TransactionsFragment(
              useSliver: true,
              items: transactions,
              isReverse: isReverse,
              useCalculatedDate: sortByCalculatedDate,
              groupSeparator: buildGroupSeparator,
            ),
          ),
        ],
      ),
    );
  }
}
