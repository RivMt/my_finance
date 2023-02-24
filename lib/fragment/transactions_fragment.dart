import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:grouped_list/sliver_grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/dialog/transaction_details_dialog.dart';
import 'package:my_finance/fragment/transaction_edit_fragment.dart';

final _transactions = StateNotifierProvider<ModelsState<Transaction>, List<Transaction>>((ref) {
  return ModelsState<Transaction>(ref);
});

final _categories = StateNotifierProvider<ModelsState<Category>, List<Category>>((ref) {
  return ModelsState<Category>(ref);
});

class TransactionsFragment extends ConsumerStatefulWidget {
  const TransactionsFragment({
    super.key,
    this.conditions,
    this.options = const {},
    this.shrinkWrap = false,
    this.useSliver = false,
    this.onEditFinish,
  });

  final List<Map<String, dynamic>>? conditions;

  final Map<String, dynamic> options;

  final Function(Transaction)? onEditFinish;

  final bool shrinkWrap;

  final bool useSliver;

  @override
  _TransactionsFragmentState createState() => _TransactionsFragmentState();
}

class _TransactionsFragmentState extends ConsumerState<TransactionsFragment> {

  /// Request transactions
  void request() {
    // Build options if it is empty
    final options = widget.options.isEmpty
        ? ApiClient.buildOptions(
      sorts: [
        const Sort(Transaction.keyPaidDate, SortType.desc),
      ],
    ) : widget.options;
    // Get transactions
    ref.read(_transactions.notifier).request(
      widget.conditions ?? [],
      options,
    );
    // Get categories
    ref.read(_categories.notifier).request([{}]);
  }

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
              onFinish: (account) {
                Navigator.pop(context, account);
              },
            ),
          ],
        );
      },
    ).then((transaction) {
      request();
      if (widget.onEditFinish != null && transaction != null) {
        widget.onEditFinish!(transaction);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    request();
  }

  @override
  void didUpdateWidget(TransactionsFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  DateTime groupBy(Transaction data) {
    final date = data.paidDate;
    return DateTime(date.year, date.month, date.day);
  }

  Widget groupSeparatorBuilder(DateTime date) => Text(
    DateFormat.yMd().format(date.toLocal()),
    style: Theme.of(context).textTheme.titleSmall,
  );

  int itemComparator(Transaction item1, Transaction item2) => item1.paidDate.compareTo(item2.paidDate);

  Widget itemBuilder(BuildContext context, Transaction data, List<Category> categories) {
    return TransactionCard(
      data: data,
      category: categories.firstWhere((element) {
        return element.type == data.type && element.pid == data.category;
      }, orElse: () => Category.unknown),
      onTap: () => showTransactionDetailsDialog(context, data),
      onLongPress: () => showTransactionEditingModal(context, data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(_transactions);
    final categories = ref.watch(_categories);
    // Return sliver grouped list view
    if (widget.useSliver) {
      return SliverGroupedListView<Transaction, DateTime>(
        elements: transactions,
        groupBy: groupBy,
        order: GroupedListOrder.DESC,
        groupSeparatorBuilder: groupSeparatorBuilder,
        itemComparator: itemComparator,
        itemBuilder: (context, data) => itemBuilder(context, data, categories),
      );
    }
    return GroupedListView<Transaction, DateTime>(
      shrinkWrap: widget.shrinkWrap,
      elements: transactions,
      groupBy: groupBy,
      order: GroupedListOrder.DESC,
      groupSeparatorBuilder: groupSeparatorBuilder,
      itemComparator: itemComparator,
      itemBuilder: (context, data) => itemBuilder(context, data, categories),
    );
  }
}