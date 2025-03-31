import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:grouped_list/sliver_grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/dialog/transaction_details_dialog.dart';
import 'package:my_finance/modal/transaction_edit_modal.dart';

class TransactionsFragment extends ConsumerWidget {
  const TransactionsFragment({
    super.key,
    required this.items,
    this.shrinkWrap = false,
    this.useSliver = false,
    this.isReverse = false,
    this.useCalculatedDate = false,
    this.groupSeparator,
  });

  final List<Transaction> items;

  final bool shrinkWrap;

  final bool useSliver;

  final bool isReverse;

  final bool useCalculatedDate;

  final String Function(DateTime)? groupSeparator;

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
            TransactionEditModal(base: editing),
          ],
        );
      },
    );
  }

  DateTime groupBy(Transaction data) {
    final date = useCalculatedDate ? data.calculatedDate : data.paidDate;
    return DateTime(date.year, date.month, date.day);
  }

  Widget groupSeparatorBuilder(BuildContext context, DateTime date) => Text(
    groupSeparator == null
        ? DateFormat.yMd().format(date.toLocal())
        : groupSeparator!(date.toLocal()),
    style: Theme.of(context).textTheme.titleSmall,
  );

  int itemComparator(Transaction item1, Transaction item2) => item1.paidDate.compareTo(item2.paidDate) * (isReverse ? -1 : 1);

  Widget itemBuilder(BuildContext context, Transaction data, List<Category> categories) {
    return TransactionCard(
      data: data,
      category: categories.firstWhere((element) {
        return element.type == data.type && element.uuid == data.categoryId;
      }, orElse: () => Category.unknown),
      isPaid: data.calculatedDate.compareTo(DateTime.now()) <= 0,
      onTap: () => showTransactionDetailsDialog(context, data),
      onLongPress: () => showTransactionEditingModal(context, data),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(provider.categories);
    // Return sliver grouped list view
    if (useSliver) {
      return SliverGroupedListView<Transaction, DateTime>(
        elements: items,
        groupBy: groupBy,
        order: isReverse ? GroupedListOrder.ASC : GroupedListOrder.DESC,
        groupSeparatorBuilder: (date) => groupSeparatorBuilder(context, date),
        itemComparator: itemComparator,
        itemBuilder: (context, data) => itemBuilder(context, data, categories),
      );
    }
    return GroupedListView<Transaction, DateTime>(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      elements: items,
      groupBy: groupBy,
      order: isReverse ? GroupedListOrder.ASC : GroupedListOrder.DESC,
      groupSeparatorBuilder: (date) => groupSeparatorBuilder(context, date),
      itemComparator: itemComparator,
      itemBuilder: (context, data) => itemBuilder(context, data, categories),
    );
  }
}