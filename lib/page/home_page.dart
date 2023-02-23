import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/condition_builder.dart';
import 'package:my_finance/dialog/main_menu_dialog.dart';
import 'package:my_finance/fragment/search_fragment.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/navigator.dart';
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
  const HomePage({
    super.key,
    required this.router,
  });

  final RouterDelegate router;

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
  void openPage(RoutePath path, [Function(dynamic)? onPageFinished]) {
    widget.router.setNewRoutePath(path).then((value) => request());
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
        onLoginRequired: () => openPage(RoutePath.login, (value) => request()),
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
    ref.read(_currentMonthExpenses.notifier).conditions = ConditionBuilder.currentMonthExpense(currency);
    ref.read(_currentMonthExpenses.notifier).request();
    // Amount to be paid
    ref.read(_amountBePaid.notifier).conditions = ConditionBuilder.amountToBePaid(currency);
    ref.read(_amountBePaid.notifier).request();
    // Budget expense
    ref.read(_budgetExpensed.notifier).conditions = ConditionBuilder.budgets(currency);
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
    widget.router.addListener(() => request());
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
                onPressed: () => openPage(FinanceRoutePath.accounts),
              ),
              build: (BuildContext context, int index) {
                final account = accounts[index];
                return AccountCard(
                  data: account,
                  onTap: () => openPage(FinanceRoutePath.accounts.details(account.pid)),
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
                    onTap = () => openPage(FinanceRoutePath.payments.extend(
                      queries: {
                        Payment.keyCurrency: currency.value,
                        FinanceModel.keyDescriptions: name,
                        FinanceRoutePath.keyMode: PaymentsPage.keyCurrentMonthExpense,
                      },
                    ));
                    break;
                  case 1:
                    name = LocaleKeys.amountBePaid.tr();
                    icon = Icons.calendar_today_outlined;
                    amount = ref.watch(_amountBePaid);
                    onTap = () => openPage(FinanceRoutePath.payments.extend(
                      queries: {
                        Payment.keyCurrency: currency.value,
                        FinanceModel.keyDescriptions: name,
                        FinanceRoutePath.keyMode: PaymentsPage.keyAmountToBePaid,
                      },
                    ));
                    break;
                  case 2:
                    name = LocaleKeys.budgetLeft.tr();
                    icon = Icons.bar_chart_outlined;
                    onTap = () => openPage(FinanceRoutePath.payments.extend(
                      queries: {
                        Payment.keyCurrency: currency.value,
                      },
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