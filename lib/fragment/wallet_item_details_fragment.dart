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
    required this.onEditButtonPressed,
    required this.onMonthChanged,
    required this.onSortButtonPressed,
    required this.onRefreshButtonPressed,
    required this.onTransactionEdit,
    this.isReverse = false,
  });

  final T item;

  final Decimal content;

  final void Function() onEditButtonPressed;

  final void Function(DateTime) onMonthChanged;

  final void Function() onSortButtonPressed;

  final void Function() onRefreshButtonPressed;

  final void Function(Transaction) onTransactionEdit;

  final List<Transaction> transactions;

  final DateTime month;

  final bool isReverse;

  @override
  State createState() => _WalletItemDetailsFragmentState<T>();
}

class _WalletItemDetailsFragmentState<T extends WalletItem> extends State<WalletItemDetailsFragment<T>> {

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text(widget.item.descriptions),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: widget.onEditButtonPressed,
            )
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(200),
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.serialNumber,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          widget.item.currency.format(widget.content),
                          style: Theme.of(context).textTheme.displayLarge,
                        )
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: Icon(widget.isReverse ? Icons.arrow_upward_outlined : Icons.arrow_downward),
                        onPressed: widget.onSortButtonPressed,
                        label: Text(LocaleKeys.sort.tr()),
                      ),
                      MonthPicker(
                        date: widget.month,
                        displayText: (date) => DateFormat.yM().format(date),
                        onDateChanged: widget.onMonthChanged,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        onPressed: widget.onRefreshButtonPressed,
                        label: Text(LocaleKeys.refresh.tr()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: TransactionsFragment(
            useSliver: true,
            items: widget.transactions,
            isReverse: widget.isReverse,
            onEditFinish: widget.onTransactionEdit,
          ),
        ),
      ],
    );
  }
}