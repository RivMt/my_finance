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

final _dateNow = DateTime.now();
final _dateBegin = DateTime(_dateNow.year, _dateNow.month, 1);
final _dateEnd = DateTime(_dateNow.year, _dateNow.month + 1, 0);

final _transactions = Provider<List<Transaction>>((ref) {
  final currency = provider.getDefaultCurrency(ref);
  return ref.watch(provider.transactions).where((item) {
    return !item.deleted
        && item.calculatedDate.compareTo(_dateBegin) >= 0
        && item.calculatedDate.compareTo(_dateEnd) == -1
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
      data[key] = [Decimal.zero, Decimal.zero];
    }
    final index = item.type == TransactionType.expense ? 0 : 1;
    data[key]![index] = data[key]![index] + item.amount;
  }
  return StatefulData(data, state);
});

final _balance = Provider<Decimal>((ref) {
  final accounts = ref.watch(provider.accounts);
  final currency = provider.getDefaultCurrency(ref);
  return accounts.fold(Decimal.zero, (prev, item) {
    if (item.currency == currency) {
      return prev + item.balance;
    }
    return prev;
  });
});

class TargetBalanceFragment extends ConsumerWidget {

  const TargetBalanceFragment({super.key});

  static const _colorExpense = Colors.redAccent;

  static const _colorIncome = Colors.greenAccent;

  String getSubtitle({
    required Currency currency,
    required Decimal balance,
    required Decimal target,
    required Decimal expense,
    required Decimal income,
  }) {
    final delta = income - expense;
    final residual = balance - target + delta;
    return LocaleKeys.msgTargetBalance.tr(namedArgs: {
      "target": currency.format(target),
      "residual": currency.format(residual.abs()),
      "judge": residual > Decimal.zero ? LocaleKeys.excess.tr() : LocaleKeys.short.tr()
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_data).data;
    final state = ref.watch(_data).state;
    final expense = ref.watch(_expense);
    final income = ref.watch(_income);
    final balance = ref.watch(_balance);
    final currency = provider.getDefaultCurrency(ref);
    final targetBalances = provider.getPreference(ref, PreferenceKeys.targetBalance);
    final target = targetBalances != null ? (targetBalances[currency.value] ?? Decimal.zero) : Decimal.zero;
    return HomeCard(
      title: LocaleKeys.targetBalance.tr(),
      subtitle: target == Decimal.zero ? "" : getSubtitle(
        currency: currency,
        target: target,
        balance: balance,
        expense: expense,
        income: income,
      ),
      state: state,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          height: 200,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceEvenly,
            minY: 0,
            maxY: (math.max(expense.toDouble(), income.toDouble()) / 9).ceil() * 10,
            baselineY: 0,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 64,
                  getTitlesWidget: (value, meta) {
                    return Text(currency.format(Decimal.parse(value.toString())));
                  },
                  showTitles: false,
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                axisNameWidget: Text(DateFormat.M().format(DateTime(
                  _dateNow.year,
                  _dateNow.month,
                  1,
                ))),
                sideTitles: SideTitles(
                  getTitlesWidget: (value, meta) {
                    return Text(DateFormat.d().format(DateTime(
                      _dateNow.year,
                      _dateNow.month,
                      value.toInt(),
                    )));
                  },
                  showTitles: true,
                ),
              ),
            ),
            barGroups: List.generate(data.keys.length, (index) {
              final key = data.keys.toList(growable: false)[index];
              return BarChartGroupData(
                  x: key.day,
                  barRods: [
                    BarChartRodData(
                      fromY: 0,
                      toY: data[key]![0].toDouble(),
                      color: _colorExpense,
                    ),
                    BarChartRodData(
                      fromY: 0,
                      toY: data[key]![1].toDouble(),
                      color: _colorIncome,
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