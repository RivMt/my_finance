import 'dart:collection';
import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/generated/locale_keys.g.dart';

typedef _DataType = SplayTreeMap<DateTime, List<Decimal>>;
typedef _TargetType = Map<dynamic, dynamic>;

final _target = Provider<_TargetType?>((ref) {
  final targets = provider.getPreference(ref, PreferenceKeys.targetBalance);
  final currency = provider.getDefaultCurrency(ref);
  if (targets == null ||
      !targets.containsKey(currency.value) ||
      !targets[currency.value]!.containsKey(ModelKeys.keyDate) ||
      !targets[currency.value]!.containsKey(ModelKeys.keyAmount)
  ) {
    return null;
  }
  return targets[currency.value];
});

final _dateNow = DateTime.now();
final _dateBegin = DateTime(_dateNow.year, _dateNow.month, _dateNow.day-14);
final _dateEnd = Provider<DateTime>((ref) {
  final target = ref.watch(_target);
  if (target == null) {
    return DateTime(_dateNow.year, _dateNow.month + 1, 0);
  }
  return target[ModelKeys.keyDate];
});

final _transactions = Provider<List<Transaction>>((ref) {
  final currency = provider.getDefaultCurrency(ref);
  return ref.watch(provider.transactions).where((item) {
    return !item.deleted
        && item.calculatedDate.compareTo(_dateBegin) >= 0
        && item.calculatedDate.compareTo(ref.watch(_dateEnd)) == -1
        && item.isIncluded
        && item.currency == currency;
  }).toList();
});

final _expense = Provider<Decimal>((ref) {
  final list = ref.watch(_transactions);
  return list.fold(Decimal.zero, (prev, item) {
    if (item.type == TransactionType.expense) {
      return prev + item.amount;
    }
    return prev;
  });
});

final _income = Provider<Decimal>((ref) {
  final list = ref.watch(_transactions);
  return list.fold(Decimal.zero, (prev, item) {
    if (item.type == TransactionType.income) {
      return prev + item.amount;
    }
    return prev;
  });
});

final _data = Provider<StatefulData<_DataType>>((ref) {
  StatefulDataState state = StatefulDataState.ready;
  // Get default currency
  final currency = provider.getDefaultCurrency(ref);
  if (currency == Currency.unknown) {
    state = StatefulDataState.error(LocaleKeys.msgUnknownDefaultCurrency.tr());
  }
  // Filter transactions
  final List<Transaction> list = ref.watch(_transactions);
  if (list.isEmpty) {
    state = StatefulDataState.loading;
  }
  // Generate chart data
  final _DataType data = SplayTreeMap();
  for(Transaction item in list) {
    final key = DateTime(item.calculatedDate.year, item.calculatedDate.month, item.calculatedDate.day);
    if (!data.containsKey(key)) {
      // Expense, Income, Withdraw, Deposit, Balance
      data[key] = [Decimal.zero, Decimal.zero, Decimal.zero, Decimal.zero, Decimal.zero];
    }
    final index = item.type.code + (item.isIncluded ? 0 : 1) * 2;
    data[key]![index] = data[key]![index] + item.amount;
  }
  // Target Balance
  DateTime key = ref.watch(_dateEnd);
  Decimal balance = ref.watch(_balance);
  if (!data.containsKey(key)) {
    data[key] = [Decimal.zero, Decimal.zero, Decimal.zero, Decimal.zero, Decimal.zero];
  }
  data[key]![4] = balance;
  // Balance history
  key = DateTime(_dateNow.year, _dateNow.month, _dateNow.day);
  if (!data.containsKey(key)) {
    data[key] = [Decimal.zero, Decimal.zero, Decimal.zero, Decimal.zero, Decimal.zero];
  }
  balance += _sum(data[key]!);
  while(key.compareTo(_dateBegin) >= 0) {
    if (data.containsKey(key)) {
      balance -= _sum(data[key]!);
      data[key]![4] = balance;
    }
    key = key.add(const Duration(days: -1));
  }
  return StatefulData(data, state);
});

final _balance = Provider<Decimal>((ref) {
  final accounts = ref.watch(provider.accounts);
  final currency = provider.getDefaultCurrency(ref);
  return accounts.fold(Decimal.zero, (prev, item) {
    if (item.currency == currency && !item.deleted) {
      return prev + item.balance;
    }
    return prev;
  });
});

/// Calculate delta of given [list]
Decimal _sum(List<Decimal> list) {
  return -list[0] + list[1] - list[2] + list[3];
}

class TargetBalanceCard extends ConsumerWidget {

  const TargetBalanceCard({super.key});

  static const _colorExpense = Colors.redAccent;

  static const _colorIncome = Colors.greenAccent;

  /// [BorderRadius] of upper direction chart bar
  final borderUp = const BorderRadius.vertical(
    top: Radius.circular(8),
    bottom: Radius.zero,
  );

  /// [BorderRadius] of upper direction chart bar
  final borderDown = const BorderRadius.vertical(
    top: Radius.zero,
    bottom: Radius.circular(8),
  );

  /// Generate subtitle from given [currency], [balance], and [target]
  String getSubtitle({
    required Currency currency,
    required Decimal balance,
    required Decimal target,
  }) {
    final residual = balance - target;
    return LocaleKeys.msgTargetBalance.tr(namedArgs: {
      "target": currency.format(target),
      "residual": currency.format(residual.abs()),
      "judge": residual > Decimal.zero ? LocaleKeys.excess.tr() : LocaleKeys.short.tr()
    });
  }

  /// Scaling chart value
  double scaleValue(double value) {
    return value;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_data).data;
    final state = ref.watch(_data).state;
    final expense = ref.watch(_expense);
    final income = ref.watch(_income);
    final balance = ref.watch(_balance);
    final currency = provider.getDefaultCurrency(ref);
    final target = ref.watch(_target);
    return HomeCard(
      title: LocaleKeys.targetBalance.tr(),
      subtitle: target == null ? "" : getSubtitle(
        currency: currency,
        target: target[ModelKeys.keyAmount],
        balance: balance,
      ),
      state: state,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          height: 200,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceEvenly,
            minY: -scaleValue((expense.toDouble() / 9).ceil() * 10),
            maxY: scaleValue((math.max(income.toDouble(), balance.toDouble()) / 9).ceil() * 10),
            gridData: FlGridData(
              drawHorizontalLine: true,
              drawVerticalLine: false,
              checkToShowHorizontalLine: (value) => value == 0.0,
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    final format = (
                        date.year != _dateNow.year ||
                        date.month != _dateNow.month ||
                        date == data.keys.first
                    ) ? DateFormat.MMMd() : DateFormat.d();
                    return Text(
                      format.format(date),
                      softWrap: true,
                      maxLines: 2,
                    );
                  },
                  showTitles: true,
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, i, rod, j) {
                  final key = data.keys.toList(growable: false)[i];
                  return BarTooltipItem(
                    "",
                    Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                    textAlign: TextAlign.start,
                    children: [
                      // Balance
                      TextSpan(
                        text: currency.format(data[key]![4]),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: AppTheme.sizeLabelLarge
                        ),
                      ),
                      const TextSpan(text: "\n"),
                      // Expense
                      TextSpan(
                        text: LocaleKeys.transactionTypeExpense.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: " "),
                      TextSpan(text: currency.format(data[key]![0])),
                      const TextSpan(text: "\n"),
                      // Income
                      TextSpan(
                        text: LocaleKeys.transactionTypeIncome.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: " "),
                      TextSpan(text: currency.format(data[key]![1])),
                      const TextSpan(text: "\n"),
                      // Delta
                      TextSpan(
                        text: LocaleKeys.delta.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: " "),
                      TextSpan(
                        text: currency.format(data[key]![3] - data[key]![2]),
                      ),
                    ]
                  );
                }
              )
            ),
            barGroups: List.generate(data.keys.length, (index) {
              final key = data.keys.toList(growable: false)[index];
              final value = _sum(data[key]!);
              final bal = data[key]![4];
              return BarChartGroupData(
                  x: key.millisecondsSinceEpoch,
                  groupVertically: true,
                  barRods: [
                    // Balance
                    BarChartRodData(
                      fromY: 0,
                      toY: scaleValue(bal.toDouble()),
                      color: _dateNow.compareTo(key) > 0
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: borderUp,
                    ),
                    // Delta
                    BarChartRodData(
                      fromY: 0,
                      toY: scaleValue(value.toDouble()),
                      color: value < Decimal.zero
                          ? _colorExpense
                          : _colorIncome,
                      borderRadius: value < Decimal.zero
                          ? borderDown
                          : borderUp,
                    ),
                  ]
              );
            }),
          )),
        ),
      ],
    );
  }
}