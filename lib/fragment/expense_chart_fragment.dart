import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_api/provider.dart' as provider;

final _expenseTransactions = Provider<StatefulData<Map<Category, Decimal>>>((ref) {
  StatefulDataState state = StatefulDataState.ready;
  final currency = provider.getDefaultCurrency(ref);
  if (currency == Currency.unknown) {
    state = StatefulDataState.error(LocaleKeys.msgUnknownDefaultCurrency.tr());
  }
  final date = ref.watch(_dateFilter);
  final begin = DateTime(date.year, date.month, 1);
  final end = DateTime(date.year, date.month + 1, 1);
  final List<Transaction> list = ref.watch(provider.transactions)
      .where((item) {
    return !item.deleted
        && item.type == TransactionType.expense
        && item.isIncluded
        && item.currency == currency
        && item.paidDate.compareTo(begin) >= 0
        && item.paidDate.compareTo(end) == -1;
  }).toList();
  if (list.isEmpty) {
    state = StatefulDataState.loading;
  }
  final List<Category> categories = ref.watch(provider.categories);
  if (categories.isEmpty) {
    state = StatefulDataState.error(LocaleKeys.msgNoCategory.tr());
  }
  Map<Category, Decimal> map = {};
  for(Transaction item in list) {
    final Category category = categories.firstWhere((element) => element.pid == item.category, orElse: () => Category.unknown);
    if (map[category] == null) {
      map[category] = Decimal.zero;
    }
    map[category] = map[category]! + item.amount;
  }
  final entries = map.entries.toList();
  entries.sort((e1, e2) => e1.value.compareTo(e2.value) * -1);
  return StatefulData(Map.fromEntries(entries), state);
});

final _dateFilter = StateNotifierProvider<ModelState<DateTime>, DateTime>((ref) {
  return ModelState<DateTime>(ref, DateTime(DateTime.now().year, DateTime.now().month, 1));
});

class ExpenseChartFragment extends ConsumerStatefulWidget {
  const ExpenseChartFragment({
    super.key,
  });

  @override
  ConsumerState createState() => _ExpenseChartFragmentState();
}

class _ExpenseChartFragmentState extends ConsumerState<ExpenseChartFragment> {

  final maxEntries = 5;

  @override
  Widget build(BuildContext context) {
    final currency = provider.getDefaultCurrency(ref);
    final map = ref.watch(_expenseTransactions).data;
    final state = ref.watch(_expenseTransactions).state;
    final total = map.values.toList(growable: false).fold(Decimal.zero, (prev, element) => prev + element);
    final entries = provider.getPreference<int>(ref, PreferenceKeys.pieChartMaxEntries) ?? maxEntries;
    return PieChartFragment<Category, Decimal>(
      title: LocaleKeys.currentMonthExpense.tr(),
      subtitle: currency.format(total),
      state: state,
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
        background: Color.lerp(Color.fromARGB(20, color.red, color.green, color.blue), Colors.white, 0.8),
      ),
      toDouble: (category, decimal) => decimal.toDouble(),
    );
  }
}