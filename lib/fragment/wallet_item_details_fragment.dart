import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class WalletItemDetailsFragment<T extends WalletItem> extends StatefulWidget {
  const WalletItemDetailsFragment({
    super.key,
    required this.item,
    required this.content,
    required this.transactions,
    required this.month,
    required this.onMonthChanged,
    required this.onSortButtonPressed,
    required this.onRefreshButtonPressed,
    required this.onTransactionEdit,
    this.isReverse = false,
    this.sortByCalculatedDate = false,
  });

  final T item;

  final Decimal content;

  final void Function(DateTime) onMonthChanged;

  final void Function() onSortButtonPressed;

  final void Function() onRefreshButtonPressed;

  final void Function(Transaction) onTransactionEdit;

  final List<Transaction> transactions;

  final DateTime month;

  final bool isReverse;

  final bool sortByCalculatedDate;

  @override
  State createState() => _WalletItemDetailsFragmentState<T>();
}

class _WalletItemDetailsFragmentState<T extends WalletItem> extends State<WalletItemDetailsFragment<T>> {

  /// Build group separator by given [date]
  String buildGroupSeparator(DateTime date) {
    if (widget.month.year != date.year) {
      return DateFormat.yMd().format(date);
    } else if (widget.month.month != date.month) {
      return DateFormat.Md().format(date);
    }
    return DateFormat.d().format(date);
  }

  @override
  Widget build(BuildContext context) {
    const height = 100.0;
    return CustomScrollView(
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
                    widget.item.serialNumber,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.swatches.contentSecondary,
                    ),
                  ),
                  Text(
                    widget.item.currency.format(widget.content),
                    style: Theme.of(context).textTheme.displayLarge,
                  )
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
                  icon: Icon(widget.isReverse ? Icons.arrow_upward_outlined : Icons.arrow_downward),
                  onPressed: widget.onSortButtonPressed,
                  label: Text(LocaleKeys.sort.tr()),
                ),
                MonthPicker(
                  date: widget.month,
                  displayText: (date) {
                    final now = DateTime.now();
                    if (date.year == now.year) {
                      return DateFormat.MMM().format(date);
                    }
                    return DateFormat.yMMM().format(date);
                  },
                  onDateChanged: widget.onMonthChanged,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  onPressed: widget.onRefreshButtonPressed,
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
            items: widget.transactions,
            isReverse: widget.isReverse,
            useCalculatedDate: widget.sortByCalculatedDate,
            groupSeparator: buildGroupSeparator,
            onEditFinish: widget.onTransactionEdit,
          ),
        ),
      ],
    );
  }
}