import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';

class TransactionsFragment extends ConsumerStatefulWidget {
  const TransactionsFragment({
    super.key,
    required this.condition,
    this.options = const {},
    this.shrinkWrap = false,
  });

  final Map<String, dynamic> condition, options;

  final bool shrinkWrap;

  @override
  _TransactionsFragmentState createState() => _TransactionsFragmentState();
}

class _TransactionsFragmentState extends ConsumerState<TransactionsFragment> {

  /// Request transactions
  void request() {
    // Build options if it is empty
    final options = widget.options.isEmpty
        ? ApiClient().buildOptions(
      sortOrderAttribute: Transaction.keyPaidDate,
      sortOrderType: SortOrderType.desc,
    ) : widget.options;
    // Get transactions
    ref.read(FinanceProvider.transactions.notifier).request(
      widget.condition,
      options,
    );
    // Get categories
    ref.read(FinanceProvider.categories.notifier).request({});
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

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(FinanceProvider.transactions);
    final categories = ref.watch(FinanceProvider.categories);
    return GroupedListView<Transaction, DateTime>(
      shrinkWrap: widget.shrinkWrap,
      elements: transactions,
      groupBy: (transaction) {
        final date = transaction.paidDate;
        return DateTime(date.year, date.month, date.day);
      },
      order: GroupedListOrder.DESC,
      groupSeparatorBuilder: (DateTime date) => Text(
        DateFormat.yMd().format(date),
        style: Theme.of(context).textTheme.titleSmall,
      ),
      itemComparator: (item1, item2) => item1.paidDate.compareTo(item2.paidDate),
      itemBuilder: (context, data) {
        return TransactionCard(
          data: data,
          category: categories.firstWhere((element) {
            return element.type == data.type && element.category == data.category;
          }, orElse: () => Category.unknown),
        );
      },
    );
  }
}