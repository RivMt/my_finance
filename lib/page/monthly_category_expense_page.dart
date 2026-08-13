import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/card/expense_chart_card.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class MonthlyCategoryExpensePage extends ConsumerStatefulWidget {
  const MonthlyCategoryExpensePage({super.key});

  @override
  ConsumerState<MonthlyCategoryExpensePage> createState() =>
      _MonthlyCategoryExpensePageState();
}

class _MonthlyCategoryExpensePageState
    extends ConsumerState<MonthlyCategoryExpensePage> {
  late DateTime _month;

  Future<void> _fetchTransactions(DateTime month) {
    final begin = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return provider.appendTransactions(ref, {
      ModelKeys.keyDeleted: false,
      ModelKeys.keyType: TransactionType.expense.code,
      ModelKeys.keyPaidDate: {
        ApiQuery.keyQueryRangeBegin: begin.toIso8601String(),
        ApiQuery.keyQueryRangeEnd: end.toIso8601String(),
      },
    });
  }

  void _onMonthChanged(DateTime month) {
    setState(() {
      _month = month;
    });
    _fetchTransactions(month);
  }

  String _displayMonth(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}년 $month월';
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTransactions(_month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.monthlyCategoryExpense.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ScreenPlanner(context).panelWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: MonthPicker(
                    date: _month,
                    displayText: _displayMonth,
                    onDateChanged: _onMonthChanged,
                  ),
                ),
                ExpenseChartCard(
                  date: _month,
                  showCard: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
