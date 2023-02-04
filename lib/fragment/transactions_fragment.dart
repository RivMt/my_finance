import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:grouped_list/sliver_grouped_list.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/provider/finance_provider.dart';

class TransactionsFragment extends ConsumerStatefulWidget {
  const TransactionsFragment({
    super.key,
    required this.condition,
    required this.currency,
    this.options = const {},
    this.shrinkWrap = false,
    this.useSliver = false,
  });

  final Map<String, dynamic> condition, options;

  final Currency currency;

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
        ? ApiClient().buildOptions(
      sortOrderAttribute: Transaction.keyPaidDate,
      sortOrderType: SortOrderType.desc,
    ) : widget.options;
    // Get transactions
    ref.read(FinanceProvider.transactions.notifier).request(
      [widget.condition],
      options,
    );
    // Get categories
    ref.read(FinanceProvider.categories.notifier).request([{}]);
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
    DateFormat.yMd().format(date),
    style: Theme.of(context).textTheme.titleSmall,
  );

  int itemComparator(Transaction item1, Transaction item2) => item1.paidDate.compareTo(item2.paidDate);

  Widget itemBuilder(BuildContext context, Transaction data, List<Category> categories) => TransactionCard(
    data: data,
    currency: widget.currency,
    category: categories.firstWhere((element) {
      return element.type == data.type && element.category == data.category;
    }, orElse: () => Category.unknown),
  );

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(FinanceProvider.transactions);
    final categories = ref.watch(FinanceProvider.categories);
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