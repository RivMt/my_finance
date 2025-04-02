import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

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
    this.isReverse = false,
    this.sortByCalculatedDate = false,
  });

  final T item;

  final Decimal content;

  final void Function(DateTime) onMonthChanged;

  final void Function() onSortButtonPressed;

  final Future<void> Function() onRefreshButtonPressed;

  final List<Transaction> transactions;

  final DateTime month;

  final bool isReverse;

  final bool sortByCalculatedDate;

  /// Build group separator by given [date]
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: Icon(isReverse ? Icons.arrow_upward_outlined : Icons.arrow_downward),
                    onPressed: onSortButtonPressed,
                    label: Text(LocaleKeys.sort.tr()),
                  ),
                  MonthPicker(
                    date: month,
                    displayText: (date) {
                      final now = DateTime.now();
                      if (date.year == now.year) {
                        return DateFormat.MMM().format(date);
                      }
                      return DateFormat.yMMM().format(date);
                    },
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