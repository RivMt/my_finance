import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_api/provider.dart' as provider;

final _expenseTransactions =
    Provider.family<StatefulData<Map<Category, Decimal>>, DateTime>(
        (ref, date) {
  StatefulDataState state = StatefulDataState.ready;
  final currency = ref.watch(provider.defaultCurrency);
  final begin = DateTime(date.year, date.month, 1);
  final end = DateTime(date.year, date.month + 1, 1);
  final List<Transaction> list = ref.watch(provider.transactions).where((item) {
    return !item.deleted &&
        item.type == TransactionType.expense &&
        item.isIncluded &&
        item.currencyId == currency.uuid &&
        item.paidDate.compareTo(begin) >= 0 &&
        item.paidDate.compareTo(end) == -1;
  }).toList();
  if (list.isEmpty) {
    state = StatefulDataState.error(LocaleKeys.msgNoTransactions.tr());
  }
  final List<Category> categories = ref.watch(provider.categories);
  if (categories.isEmpty) {
    state = StatefulDataState.error(LocaleKeys.msgNoCategory.tr());
  }
  final Map<Category, Decimal> map = {};
  for (Transaction item in list) {
    final Category category = categories.firstWhere(
        (element) => element.uuid == item.categoryId,
        orElse: () => Category.unknown);
    if (map[category] == null) {
      map[category] = Decimal.zero;
    }
    map[category] = map[category]! + item.amount;
  }
  final entries = map.entries.toList();
  entries.sort((e1, e2) => e1.value.compareTo(e2.value) * -1);
  return StatefulData(Map.fromEntries(entries), state);
});

final _dateFilter = StateNotifierProvider<ValueStateNotifier<DateTime>, DateTime>((ref) {
  return ValueStateNotifier<DateTime>(DateTime(DateTime.now().year, DateTime.now().month, 1));
});

/// Charts the current month's included expenses by category.
class ExpenseChartCard extends ConsumerStatefulWidget {
  const ExpenseChartCard({
    super.key,
    this.date,
    this.title,
    this.onOpenPressed,
    this.showCard = true,
  });

  final DateTime? date;

  final String? title;

  final VoidCallback? onOpenPressed;

  final bool showCard;

  @override
  ConsumerState createState() => _ExpenseChartFragmentCard();
}

class _ExpenseChartFragmentCard extends ConsumerState<ExpenseChartCard> {
  final maxEntries = 5;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = widget.date ?? DateTime(now.year, now.month, 1);
    final currency = ref.watch(provider.defaultCurrency);
    final expenseTransactions = ref.watch(_expenseTransactions(date));
    final map = expenseTransactions.data;
    final state = expenseTransactions.state;
    final total = map.values
        .toList(growable: false)
        .fold(Decimal.zero, (prev, element) => prev + element);
    final root = ref.watch(provider.financePreference);
    final entries =
        root.get<int>(PreferenceKeys.pieChartMaxEntries, maxEntries).value;
    return PieChartFragment<Category, Decimal>(
      title: widget.title ?? LocaleKeys.currentMonthExpense.tr(),
      subtitle: currency.format(total),
      state: state,
      showCard: widget.showCard,
      button: widget.onOpenPressed == null
          ? null
          : IconButton(
              tooltip: LocaleKeys.monthlyCategoryExpense.tr(),
              icon: const Icon(Icons.arrow_forward),
              onPressed: widget.onOpenPressed,
            ),
      keys: map.keys.toList(),
      values: map.values.toList(),
      entries: entries,
      width: 200,
      height: 200,
      getName: (category) => category.name,
      getDescription: (category, decimal) => currency.format(decimal),
      getIcon: (category, color) => CategoryIcon(
        type: category.type,
        icon: category.icon.icon,
        foreground: color,
        background: Color.lerp(
            Color.fromARGB(20, color.red, color.green, color.blue),
            Colors.white,
            0.8),
      ),
      toDouble: (category, decimal) => decimal.toDouble(),
    );
  }
}
