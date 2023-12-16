import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/local_provider.dart'as local_provider;
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/preference_keys.dart';

Currency _currentCurrency(ref) => Currency.fromValue(ref.watch(provider.preferences)[PreferenceKeys.defaultCurrency]?.value);

final _expenseTransactions = Provider<Map<Category, Decimal>>((ref) {
  final currency = _currentCurrency(ref);
  final List<Transaction> list = ref.watch(local_provider.transactions)
      .where((item) => (!item.deleted && item.type == TransactionType.expense && item.isIncluded && item.currency == currency)).toList();
  final List<Category> categories = ref.watch(provider.categories);
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
  return Map.fromEntries(entries);
});

final _totalExpense = Provider<Decimal>((ref) {
  final currency = _currentCurrency(ref);
  final List<Transaction> list = ref.watch(local_provider.transactions).where((item) => item.currency == currency).toList();
  Decimal total = Decimal.zero;
  for(Transaction item in list) {
    total += item.amount;
  }
  return total;
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
    final currency = _currentCurrency(ref);
    final map = ref.watch(_expenseTransactions);
    return PieChartFragment<Category, Decimal>(
      title: LocaleKeys.currentMonthExpense.tr(),
      subtitle: currency.format(ref.watch(_totalExpense)),
      keys: map.keys.toList(),
      values: map.values.toList(),
      entries: maxEntries,
      width: 400,
      height: 400,
      getName: (category) => category.name,
      getDescription: (category, decimal) => currency.format(decimal),
      getIcon: (category) => CategoryIcon.fromCategory(category),
      toDouble: (category, decimal) => decimal.toDouble(),
    );
  }
}