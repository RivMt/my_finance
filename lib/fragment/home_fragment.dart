import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/fragment/expense_chart_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/preference_keys.dart';

final _filteredAccounts = Provider<List<Account>>((ref) {
  final sort = ref.watch(_sortFilter);
  List<Account> list = ref.watch(provider.accounts);
  if (Account.unknown.map.containsKey(sort)) {
    list.sort((a1, a2) =>
        (a1.map[sort] as Comparable).compareTo(a2.map[sort]));
  }
  return list.sublist(0, math.min(2, list.length));
});

final _sortFilter = StateNotifierProvider<ModelState<String>, String>((ref) {
  return ModelState<String>(ref, ModelKeys.keyLastUsed);
});

final _amountBePaid = StateNotifierProvider<CalculateValueState<Transaction>, Decimal>((ref) {
  return CalculateValueState<Transaction>(ref,
    conditions: [],
    type: CalculationType.sum,
    attribute: ModelKeys.keyAmount,
  );
});

final _budgetExpensed = StateNotifierProvider<CalculateValueState<Transaction>, Decimal>((ref) {
  return CalculateValueState<Transaction>(ref,
    conditions: [],
    type: CalculationType.sum,
    attribute: ModelKeys.keyAmount,
    queries: {
      "mode": "budget",
    }
  );
});

class HomeFragment extends ConsumerStatefulWidget {

  static const String route = "/";

  const HomeFragment({super.key});

  @override
  ConsumerState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomeFragment> {

  static const String _tag = "HomePage";

  final client = ApiClient();

  /// Currently selected [Currency]
  ///
  /// **DO NOT** access directly in [build]. Use [currency] alternatively.
  Currency? _currency;

  /// Currently selected [Currency]
  Currency get currency {
    if (_currency != null) {
      return _currency!;
    }
    final prefs = ref.watch(provider.preferences);
    return Currency.fromValue(prefs[PreferenceKeys.defaultCurrency]?.value);
  }

  set currency(Currency c) => _currency = c;

  /// Open [page]
  ///
  /// After [page] has been pop, triggers [onPageFinished] if it is not `null`.
  void openPage(Widget page, [Function(dynamic)? onPageFinished]) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page)).then((value) {
      if (onPageFinished != null) {
        onPageFinished(value);
      }
    }).then((value) {
      request();
    });
  }

  /// Request data
  void request() async {
    final now = DateTime.now();
    final last = DateTime(now.year, now.month+1, 1, 0, 0, 0, 0);
    assert(now.timeZoneOffset == last.timeZoneOffset);
    final duration = now.timeZoneOffset;
    // Preference
    await ref.read(provider.preferences.notifier).request();
    // Amount to be paid
    ref.read(_amountBePaid.notifier).conditions = [{
      ModelKeys.keyType: TransactionType.expense.code,
      ModelKeys.keyCalculatedDate: {
        "min": now.add(duration).add(const Duration(seconds: 1)).millisecondsSinceEpoch,
        "max": last.add(duration).millisecondsSinceEpoch,
      },
      ModelKeys.keyCurrency: currency.value,
      ModelKeys.keyIncluded: true,
      ModelKeys.keyDeleted: false,
    }];
    ref.read(_amountBePaid.notifier).request();
    // expense
    setState(() {});
  }

  /// Triggers on payment group card button pressed
  void onPaymentGroupButtonPressed(Currency currency) {
    this.currency = currency;
    request();
  }

  /// Triggers on transaction created
  void onTransactionCreated(Transaction? transaction) {
    if (transaction != null) {
      request();
    }
  }

  /// Get [GridView] cross axis count
  ///
  /// Value is always bigger than `0`
  int getCrossAxisCount(BuildContext context) => ScreenPlanner(context).panelNumber;

  /// Get [GridView] child aspect ratio
  double getChildAspectRatio(BuildContext context) {
    return (MediaQuery.of(context).size.width / getCrossAxisCount(context)) / GroupCard.height;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(HomeFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ExpenseChartFragment(),
          ),
        ],
      ),
    );
  }
}