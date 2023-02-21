import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/dialog/main_menu_dialog.dart';
import 'package:my_finance/fragment/search_fragment.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/page/account_details_page.dart';
import 'package:my_finance/page/accounts_page.dart';
import 'package:my_finance/page/payments_page.dart';
import 'package:my_finance/preference_keys.dart';

final _accounts = StateNotifierProvider<ModelsState<Account>, List<Account>>((ref) {
  return ModelsState<Account>(ref);
});

final _currentMonthExpenses = StateNotifierProvider<CalculateValueState<Transaction>, Decimal>((ref) {
  return CalculateValueState<Transaction>(ref,
    conditions: [],
    type: CalculationType.sum,
    attribute: Transaction.keyAmount,
  );
});

final _amountBePaid = StateNotifierProvider<CalculateValueState<Transaction>, Decimal>((ref) {
  return CalculateValueState<Transaction>(ref,
    conditions: [],
    type: CalculationType.sum,
    attribute: Transaction.keyAmount,
  );
});

final _budgetExpensed = StateNotifierProvider<CalculateValueState<Transaction>, Decimal>((ref) {
  return CalculateValueState<Transaction>(ref,
    conditions: [],
    type: CalculationType.sum,
    attribute: Transaction.keyAmount,
    queries: {
      "mode": "budget",
    }
  );
});

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {

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
    final prefs = ref.watch(preferenceProvider);
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

  /// Init API
  void init() async {
    // Init preference
    ref.read(preferenceProvider.notifier).setDefaults({
      PreferenceKeys.defaultCurrency: Currency.unknown.value,
      PreferenceKeys.budgets: {},
    });
    // Login or authenticate
    try {
      final Map<String, dynamic> prefs = jsonDecode(await rootBundle.loadString("assets/key/server.json"));
      await client.init(
        onLoginRequired: () => openPage(const LoginPage(), (value) => request()),
        preferences: prefs,
      );
    } on Exception catch(e) {
      Log.e(_tag, "Error: $e");
      return;
    }
    // Request
    request();
  }

  /// Request data
  void request() async {
    final now = DateTime.now();
    // Account
    ref.read(_accounts.notifier).request(
      [{
        FinanceModel.keyDeleted: false,
      }],
      ApiClient.buildOptions(
        limit: 3,
        sorts: [
          const Sort(Account.keyPriority, SortType.asc),
        ],
      ),
    );
    // Preference
    await ref.read(preferenceProvider.notifier).request();
    // Current month expense
    ref.read(_currentMonthExpenses.notifier).conditions = [{
      Transaction.keyType: TransactionType.expense.code,
      Transaction.keyPaidDate: [
        DateTime(now.year, now.month, 1, 0, 0, 0, 0).millisecondsSinceEpoch,
        DateTime(now.year, now.month+1, 1, 0, 0, 0, 0).millisecondsSinceEpoch,
      ],
      Transaction.keyCurrency: currency.value,
      Transaction.keyIncluded: true,
      FinanceModel.keyDeleted: false,
    }];
    ref.read(_currentMonthExpenses.notifier).request();
    // Amount to be paid
    ref.read(_amountBePaid.notifier).conditions = [{
      Transaction.keyType: TransactionType.expense.code,
      Transaction.keyCalculatedDate: [
        now.millisecondsSinceEpoch,
      ],
      Transaction.keyCurrency: currency.value,
      Transaction.keyIncluded: true,
      FinanceModel.keyDeleted: false,
    }];
    ref.read(_amountBePaid.notifier).request();
    // Budget expense
    ref.read(_budgetExpensed.notifier).conditions = [{
      Transaction.keyType: TransactionType.expense.code,
      Transaction.keyCurrency: currency.value,
      Transaction.keyIncluded: true,
      FinanceModel.keyDeleted: false,
      Transaction.keyPaidDate: {
        "max": DateTime(now.year, now.month+1, 0).millisecondsSinceEpoch,
      },
      Transaction.keyUtilityEnd: {
        "min": DateTime(now.year, now.month, 1).millisecondsSinceEpoch,
      }
    }];
    ref.read(_budgetExpensed.notifier).request();
    setState(() {});
  }

  /// Triggers on menu button pressed
  void onMenuButtonPressed() {
    showDialog(
      context: context,
      builder: (context) => MainMenuDialog(
        onAccountButtonPressed: init,
        onRefreshPressed: request,
      ),
    );
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
    init();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(_accounts);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: onMenuButtonPressed,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () => showSearch(
              context: context,
              delegate: SearchFragment(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: getCrossAxisCount(context),
            childAspectRatio: getChildAspectRatio(context),
            mainAxisSpacing: 8,
          ),
          children: [
            GroupCard(
              title: LocaleKeys.account.plural(1),
              count: accounts.length,
              button: IconButton(
                icon: const Icon(Icons.keyboard_arrow_right_outlined),
                color: Theme.of(context).textTheme.titleMedium?.color,
                onPressed: () => openPage(const AccountsPage()),
              ),
              build: (BuildContext context, int index) {
                final account = accounts[index];
                return AccountCard(
                  data: account,
                  onTap: () => openPage(AccountDetailsPage(pid: account.pid)),
                );
              },
            ),
            GroupCard(
              title: LocaleKeys.payment.plural(1),
              count: 3,
              button: PopupMenuButton(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
                onSelected: onPaymentGroupButtonPressed,
                itemBuilder: (BuildContext context) => Currency.validValues.map((currency) {
                  return PopupMenuItem(
                    value: currency,
                    child: CurrencyCard(
                      data: currency,
                      useIconBackground: false,
                    ),
                  );
                }).toList(growable: false),
              ),
              build: (BuildContext context, int index) {
                late String name;
                late IconData icon;
                late Decimal amount;
                late Function() onTap;
                switch(index) {
                  case 0:
                    name = LocaleKeys.currentMonthExpense.tr();
                    icon = Icons.payments_outlined;
                    amount = ref.watch(_currentMonthExpenses);
                    onTap = () => openPage(PaymentsPage(
                      subtitle: name,
                      currency: currency,
                      condition: ref.watch(_currentMonthExpenses.notifier).conditions,
                    ));
                    break;
                  case 1:
                    name = LocaleKeys.amountBePaid.tr();
                    icon = Icons.calendar_today_outlined;
                    amount = ref.watch(_amountBePaid);
                    onTap = () => openPage(PaymentsPage(
                      subtitle: name,
                      currency: currency,
                      condition: ref.watch(_amountBePaid.notifier).conditions,
                    ));
                    break;
                  case 2:
                    name = LocaleKeys.budgetLeft.tr();
                    icon = Icons.bar_chart_outlined;
                    onTap = () => openPage(PaymentsPage(
                      currency: currency,
                    ));
                    final budgetExpensed = ref.watch(_budgetExpensed);
                    final pref = ref.watch(preferenceProvider)[PreferenceKeys.budgets];
                    if (pref != null && pref.value is Map && pref.value.containsKey(currency.value)) {
                      amount = pref.value[currency.value] - budgetExpensed;
                    } else {
                      amount = Decimal.zero;
                    }
                    break;
                  default:
                    name = "???";
                    icon = Icons.question_mark_outlined;
                    onTap = () {};
                    amount = Decimal.zero;
                }
                return WalletItemCard(
                  title: currency.format(amount),
                  subtitle: name,
                  foreground: Colors.white,
                  background: Theme.of(context).primaryColor,
                  icon: icon,
                  onTap: onTap,
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: TransactionAddButton(
        onFinish: onTransactionCreated,
      ),
    );
  }
}