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

/// Charts the current month's included expenses by category.
class ExpenseChartCard extends ConsumerStatefulWidget {
  const ExpenseChartCard({
    super.key,
    this.date,
    this.title,
    this.onOpenPressed,
    this.onClosePressed,
    this.onDateChanged,
    this.isExpanded = false,
    this.expansionProgress = 1,
    this.showCard = true,
  });

  final DateTime? date;

  final String? title;

  final VoidCallback? onOpenPressed;

  final VoidCallback? onClosePressed;

  final ValueChanged<DateTime>? onDateChanged;

  final bool isExpanded;

  final double expansionProgress;

  final bool showCard;

  @override
  ConsumerState createState() => _ExpenseChartFragmentCard();
}

class _ExpenseChartFragmentCard extends ConsumerState<ExpenseChartCard> {

  // TODO: Fix API `entries` to nullable
  int get maxEntries => widget.isExpanded ? 100 : 5;

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
    final expansionProgress = widget.expansionProgress.clamp(0.0, 1.0);
    final button = widget.isExpanded
        ? SizedBox.square(
            dimension: 48,
            child: Stack(
              children: [
                IgnorePointer(
                  ignoring: expansionProgress >= 0.5,
                  child: Opacity(
                    opacity: 1 - expansionProgress,
                    child: IconButton(
                      tooltip: LocaleKeys.monthlyCategoryExpense.tr(),
                      icon: const Icon(Icons.fullscreen),
                      onPressed: () {},
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: expansionProgress < 0.5,
                  child: Opacity(
                    opacity: expansionProgress,
                    child: IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      icon: const Icon(Icons.fullscreen_exit),
                      onPressed: widget.onClosePressed,
                    ),
                  ),
                ),
              ],
            ),
          )
        : widget.onOpenPressed == null
            ? null
            : IconButton(
                tooltip: LocaleKeys.monthlyCategoryExpense.tr(),
                icon: const Icon(Icons.fullscreen),
                onPressed: widget.onOpenPressed,
              );

    PieChartFragment<Category, Decimal> buildChart({
      required StatefulDataState chartState,
      required bool showCard,
      Widget? chartButton,
    }) {
      final expandedSize = MediaQuery.sizeOf(context).shortestSide * 0.5;
      final maxChartSize = expandedSize.clamp(200.0, 320.0);
      final chartSize = widget.isExpanded
          ? 200 + (maxChartSize - 200) * expansionProgress
          : 200.0;
      return PieChartFragment<Category, Decimal>(
        title: widget.title ?? LocaleKeys.currentMonthExpense.tr(),
        subtitle: currency.format(total),
        state: chartState,
        showCard: showCard,
        button: chartButton,
        keys: map.keys.toList(),
        values: map.values.toList(),
        entries: entries,
        width: chartSize,
        height: chartSize,
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

    if (!widget.isExpanded) {
      return buildChart(
        chartState: state,
        showCard: widget.showCard,
        chartButton: button,
      );
    }

    final isCurrentMonth = date.year == now.year && date.month == now.month;
    return HomeCard(
      title: widget.title ??
          (isCurrentMonth
              ? LocaleKeys.currentMonthExpense.tr()
              : LocaleKeys.monthlyCategoryExpense.tr()),
      subtitle: currency.format(total),
      state: StatefulDataState.ready,
      button: button,
      children: [
        ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: expansionProgress,
            child: Opacity(
              opacity: expansionProgress,
              child: MonthPicker(
                date: date,
                onDateChanged: widget.onDateChanged ?? (_) {},
              ),
            ),
          ),
        ),
        buildChart(
          chartState: state,
          showCard: false,
        ),
      ],
    );
  }
}
