import 'dart:collection';
import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/core/model/preference_element.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/generated/locale_keys.g.dart';

const String _tag = "TargetBalanceCard";

typedef _DataType = SplayTreeMap<DateTime, List<Decimal>>;

final _target = Provider<PreferenceElement?>((ref) {
  final root = ref.watch(provider.financePreference);
  final currency = ref.watch(provider.defaultCurrency);
  final targets = root.get(PreferenceKeys.targetBalance, null);
  if (!targets.containsKey(currency.uuid)) {
    Log.i(_tag, "No target balances for default currency: $currency");
    return null;
  }
  return targets.get(currency.uuid, null);
});

final _dateNow = DateTime.now();

final _dateBegin = DateTime(_dateNow.year, _dateNow.month, _dateNow.day-7);

final _dateEnd = Provider<DateTime>((ref) {
  final defaultDate = DateTime(_dateNow.year, _dateNow.month + 1, 0);
  final target = ref.watch(_target);
  if (target == null) {
    return defaultDate;
  }
  final dates = <DateTime>[];
  for(PreferenceElement element in target.children) {
    try {
      final date = DateTime.parse(element.key);
      if (date.isBefore(DateTime.now())) {
        continue;
      }
      dates.add(date);
    } on FormatException {
      Log.e(_tag, "Unable to parse target balance key: ${element.key}");
    }
  }
  if (dates.isEmpty) {
    return defaultDate;
  }
  dates.sort();
  return dates[0];
});

final _transactions = Provider<List<Transaction>>((ref) {
  final currency = ref.watch(provider.defaultCurrency);
  return ref.watch(provider.transactions).where((item) {
    return !item.deleted
        && item.calculatedDate.compareTo(_dateBegin) >= 0
        && item.calculatedDate.compareTo(ref.watch(_dateEnd)) == -1
        && item.currencyId == currency.uuid;
  }).toList();
});

final _max = Provider<List<double>>((ref) {
  final list = <double>[
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
  ];
  final items = ref.watch(_data).data.values;
  for(List<Decimal> item in items) {
    for(int i=0; i < list.length; i++) {
      list[i] = math.max(list[i], item[i].toDouble().abs());
    }
  }
  return list;
});

final _balance = Provider<Decimal>((ref) {
  final accounts = ref.watch(provider.accounts);
  final currency = ref.watch(provider.defaultCurrency);
  return accounts.fold(Decimal.zero, (prev, item) {
    if (item.currencyId == currency.uuid && !item.deleted) {
      return prev + item.balance;
    }
    return prev;
  });
});

final _data = Provider<StatefulData<_DataType>>((ref) {
  StatefulDataState state = StatefulDataState.ready;
  // Check logged in
  final user = ref.watch(provider.currentUser);
  if (!user.isValid) {
    state = StatefulDataState.loading;
  }
  // Get default currency
  final currency = ref.watch(provider.defaultCurrency);
  if (currency == Currency.unknown) {
    state = StatefulDataState.error(LocaleKeys.msgUnknownDefaultCurrency.tr());
  }
  // Filter transactions
  final List<Transaction> list = ref.watch(_transactions);
  if (list.isEmpty) {
    state = StatefulDataState.error(LocaleKeys.msgNoTransactions.tr());
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
  final DateTime end = ref.watch(_dateEnd);
  Decimal balance = ref.watch(_balance);
  if (!data.containsKey(end)) {
    data[end] = [Decimal.zero, Decimal.zero, Decimal.zero, Decimal.zero, Decimal.zero];
  }
  data[end]![4] = balance;
  // Balances
  final DateTime now = DateTime(_dateNow.year, _dateNow.month, _dateNow.day);
  if (!data.containsKey(now)) {
    data[now] = [Decimal.zero, Decimal.zero, Decimal.zero, Decimal.zero, Decimal.zero];
  }
  for(DateTime key in data.keys.toList().reversed) {
    if (key.compareTo(now) > 0) {
      continue;
    }
    data[key]![4] = balance;
    balance -= _sum(data[key]!);
  }
  balance = ref.watch(_balance);
  for(DateTime key in data.keys.toList()) {
    if (key.compareTo(now) <= 0) {
      continue;
    }
    balance += _sum(data[key]!);
    data[key]![4] = balance;
  }
  return StatefulData(data, state);
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
  final _borderUp = const BorderRadius.vertical(
    top: Radius.circular(8),
    bottom: Radius.zero,
  );

  /// [BorderRadius] of upper direction chart bar
  final _borderDown = const BorderRadius.vertical(
    top: Radius.zero,
    bottom: Radius.circular(8),
  );

  /// Height of bar chart
  final _height = 90.0;

  /// Minimum size of bar height
  final _minBarHeight = 10.0;

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
  double scaleValue({
    required double value,
    required double max,
    required double factor,
  }) {
    if (value == 0 || max == 0) return 0;
    return math.max(
      _minBarHeight,
      math.sqrt(1 - math.pow(value.abs() / max - 1, 2)) * _height * factor,
    ) * value.sign;
  }

  /// Factor of bar scale
  ///
  /// [local] is local maximum, [global] is global maximum.
  double scaleFactor(double local, double global) {
    return 0.5 + local/global * 0.5;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider
    final raw = ref.watch(_data);
    final data = raw.data;
    final state = raw.state;
    final dateEnd = ref.watch(_dateEnd);
    final balance = data[dateEnd]![4];
    final currency = ref.watch(provider.defaultCurrency);
    final targets = ref.watch(_target);
    final target = targets?.get(dateEnd.toIso8601String(), null);
    // Value scaling
    final maxes = ref.watch(_max);
    final deltaMax = math.max(maxes[0], maxes[1]);
    final globalMax = math.max(deltaMax, maxes[4]);
    return HomeCard(
      title: LocaleKeys.targetBalance.tr(),
      subtitle: target == null ? "" : getSubtitle(
        currency: currency,
        target: target.value,
        balance: balance,
      ),
      state: state,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          height: _height*2 + 32,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceEvenly,
            minY: -(_height + 10),
            maxY: _height + 10,
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
                        (date.compareTo(_dateNow) > 0 || date == data.keys.first) &&
                            !(date.year == _dateNow.year && date.month == _dateNow.month)
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
                getTooltipColor: (group) => Theme.of(context).colorScheme.inverseSurface,
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
              final bal = scaleValue(
                value: data[key]![4].toDouble(),
                max: maxes[4],
                factor: scaleFactor(maxes[4], globalMax),
              );
              return BarChartGroupData(
                x: key.millisecondsSinceEpoch,
                groupVertically: true,
                barRods: [
                  // Balance
                  if (maxes[4] > 0)
                    BarChartRodData(
                      fromY: 0,
                      toY: bal,
                      color: _dateNow.compareTo(key) > 0
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: bal > 0 ? _borderUp : _borderDown,
                    ),
                  // Expense
                  if (maxes[0] > 0)
                    BarChartRodData(
                      fromY: 0,
                      toY: -scaleValue(
                        value: data[key]![0].toDouble(),
                        max: maxes[0],
                        factor: scaleFactor(maxes[0], globalMax),
                      ),
                      color: _colorExpense,
                      borderRadius: _borderDown,
                    ),
                  // Income
                  if (maxes[1] > 0)
                    BarChartRodData(
                      fromY: 0,
                      toY: scaleValue(
                        value: data[key]![1].toDouble(),
                        max: maxes[1],
                        factor: scaleFactor(maxes[1], globalMax),
                      ),
                      color: _colorIncome,
                      borderRadius: _borderUp,
                    ),
                ],
              );
            }),
          )),
        ),
      ],
    );
  }
}