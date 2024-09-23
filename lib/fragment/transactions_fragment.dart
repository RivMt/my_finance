import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:grouped_list/sliver_grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/dialog/transaction_details_dialog.dart';
import 'package:my_finance/fragment/transaction_edit_fragment.dart';

class TransactionsFragment extends ConsumerStatefulWidget {
  const TransactionsFragment({
    super.key,
    required this.items,
    this.shrinkWrap = false,
    this.useSliver = false,
    this.onEditFinish,
    this.isReverse = false,
    this.useCalculatedDate = false,
    this.groupSeparator,
  });

  final List<Transaction> items;

  final Function(Transaction)? onEditFinish;

  final bool shrinkWrap;

  final bool useSliver;

  final bool isReverse;

  final bool useCalculatedDate;

  final String Function(DateTime)? groupSeparator;

  @override
  ConsumerState createState() => _TransactionsFragmentState();
}

class _TransactionsFragmentState extends ConsumerState<TransactionsFragment> {

  /// Show transaction details dialog
  void showTransactionDetailsDialog(BuildContext context, Transaction data) {
    showDialog(
      context: context,
      builder: (context) => TransactionDetailsDialog(
        data: data,
      ),
    );
  }

  /// Show transaction editing modal
  void showTransactionEditingModal(BuildContext context, [Transaction? transaction]) async {
    Transaction? editing = transaction;
    showModalBottomSheet<Transaction>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) {
        return Wrap(
          children: [
            TransactionEditFragment(
              base: editing,
              isEdit: true,
              onFinish: (account) {
                Navigator.pop(context, account);
              },
            ),
          ],
        );
      },
    ).then((transaction) {
      if (widget.onEditFinish != null && transaction != null) {
        widget.onEditFinish!(transaction);
      }
    });
  }

  DateTime groupBy(Transaction data) {
    final date = widget.useCalculatedDate ? data.calculatedDate : data.paidDate;
    return DateTime(date.year, date.month, date.day);
  }

  Widget groupSeparatorBuilder(DateTime date) => Text(
    widget.groupSeparator == null
        ? DateFormat.yMd().format(date.toLocal())
        : widget.groupSeparator!(date.toLocal()),
    style: Theme.of(context).textTheme.titleSmall,
  );

  int itemComparator(Transaction item1, Transaction item2) => item1.paidDate.compareTo(item2.paidDate) * (widget.isReverse ? -1 : 1);

  Widget itemBuilder(BuildContext context, Transaction data, List<Category> categories) {
    return TransactionCard(
      data: data,
      category: categories.firstWhere((element) {
        return element.type == data.type && element.pid == data.category;
      }, orElse: () => Category.unknown),
      isPaid: data.calculatedDate.compareTo(DateTime.now()) <= 0,
      onTap: () => showTransactionDetailsDialog(context, data),
      onLongPress: () => showTransactionEditingModal(context, data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(provider.categories);
    // Return sliver grouped list view
    if (widget.useSliver) {
      return SliverGroupedListView<Transaction, DateTime>(
        elements: widget.items,
        groupBy: groupBy,
        order: widget.isReverse ? GroupedListOrder.ASC : GroupedListOrder.DESC,
        groupSeparatorBuilder: groupSeparatorBuilder,
        itemComparator: itemComparator,
        itemBuilder: (context, data) => itemBuilder(context, data, categories),
      );
    }
    return GroupedListView<Transaction, DateTime>(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: widget.shrinkWrap,
      elements: widget.items,
      groupBy: groupBy,
      order: widget.isReverse ? GroupedListOrder.ASC : GroupedListOrder.DESC,
      groupSeparatorBuilder: groupSeparatorBuilder,
      itemComparator: itemComparator,
      itemBuilder: (context, data) => itemBuilder(context, data, categories),
    );
  }
}