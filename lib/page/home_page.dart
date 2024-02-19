import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/dialog/main_menu_dialog.dart';
import 'package:my_finance/fragment/accounts_fragment.dart';
import 'package:my_finance/fragment/home_fragment.dart';
import 'package:my_finance/fragment/payments_fragment.dart';
import 'package:my_finance/navigator.dart';
import 'package:my_finance/page/search_page.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/preference_keys.dart';
import 'package:my_finance/local_provider.dart' as local_provider;

final _filteredAccounts = Provider<List<Account>>((ref) {
  final min = ref.watch(_minPriorityFilter);
  final max = ref.watch(_maxPriorityFilter);
  final sort = ref.watch(_sortFilter);
  final list = ref.watch(provider.accounts);
  List<Account> result = list
      .where((account) => (account.priority >= min && account.priority <= max)).toList();
  if (Account.unknown.map.containsKey(sort)) {
    result.sort((a1, a2) =>
        (a1.map[sort] as Comparable).compareTo(a2.map[sort]));
  }
  return result;
});

final _filteredPayments = Provider<List<Payment>>((ref) {
  final min = ref.watch(_minPriorityFilter);
  final max = ref.watch(_maxPriorityFilter);
  final sort = ref.watch(_sortFilter);
  final list = ref.watch(provider.payments);
  List<Payment> result = list
      .where((payment) => (payment.priority >= min && payment.priority <= max)).toList();
  if ( Payment.unknown.map.containsKey(sort)) {
    result.sort((a1, a2) =>
        (a1.map[sort] as Comparable).compareTo(a2.map[sort]));
  }
  return result;
});

final _minPriorityFilter = StateNotifierProvider<ModelState<int>, int>((ref) {
  return ModelState<int>(ref, 0);
});

final _maxPriorityFilter = StateNotifierProvider<ModelState<int>, int>((ref) {
  return ModelState<int>(ref, 1000);
});

final _sortFilter = StateNotifierProvider<ModelState<String>, String>((ref) {
  return ModelState<String>(ref, ModelKeys.keyPid);
});

class HomePage extends ConsumerStatefulWidget {

  const HomePage({
    super.key,
    required this.router,
  });

  final FinanceRouterDelegate router;

  @override
  ConsumerState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {

  static const String _tag = "HomePage";

  final client = ApiClient();

  final List<_NavigationDestinations> railDestinations = [
    _NavigationDestinations(
      icon: const Icon(Icons.explore_outlined),
      selectedIcon: const Icon(Icons.explore),
      label: LocaleKeys.home.tr(),
    ),
    _NavigationDestinations(
      icon: const Icon(Icons.folder_copy_outlined),
      selectedIcon: const Icon(Icons.folder_copy),
      label: LocaleKeys.account.plural(1),
    ),
    _NavigationDestinations(
      icon: const Icon(Icons.payments_outlined),
      selectedIcon: const Icon(Icons.payments),
      label: LocaleKeys.payment.plural(1),
    ),
  ];

  List<_NavigationDestinations> get barDestinations {
    final List<_NavigationDestinations> list = [];
    for(int i=0; i < railDestinations.length; i++) {
      list.add(railDestinations[convertNavigationIndex(i)]);
    }
    return list;
  }

  /// Index of [NavigationRail]
  int navigationRailIndex = 0;

  /// Index of [BottomNavigationBar]
  int get navigationBarIndex => convertNavigationIndex(navigationRailIndex);

  /// Open [page]
  ///
  /// After [page] has been pop, triggers [onPageFinished] if it is not `null`.
  void openPage(RoutePath path, [Function(dynamic)? onPageFinished]) {
    widget.router.setNewRoutePath(path).then(onPageFinished ?? (value) {});
  }

  /// Refresh all data
  void refreshAll() async {
    // Login or authenticate
    try {
      final Map<String, dynamic> prefs = jsonDecode(await rootBundle.loadString("assets/key/server.json"));
      await client.init(
        onLoginRequired: () => openPage(RoutePath.login, (value) => refresh()),
        preferences: prefs,
      );
      // Refresh providers
      provider.refreshAccounts(ref);
      provider.refreshPayments(ref);
      provider.refreshCategories(ref);
      provider.syncPreferences(ref, {
        PreferenceKeys.defaultCurrency: Currency.unknown.value,
        PreferenceKeys.budgets: {},
      });
    } on Exception catch(e) {
      Log.e(_tag, "Error: $e");
      return;
    }
    // Refresh widgets
    refresh();
  }

  /// Refresh transaction data
  void refresh() async {
    // Request
    final now = DateTime.now();
    local_provider.refreshTransactions(ref, [{
      ModelKeys.keyPaidDate: [
        DateTime(now.year, now.month, 1).millisecondsSinceEpoch,
        DateTime(now.year, now.month+1, 0).millisecondsSinceEpoch,
      ]
    }]);
  }

  /// Convert [NavigationRail] index to [BottomNavigationBar] index
  int convertNavigationIndex(int index) {
    if (index == 0) {
      return 1;
    } else if (index == 1) {
      return 0;
    }
    return index;
  }

  /// Triggers on [navigationRailIndex] changed
  void onNavigationIndexChanged(int index) {
    setState(() {
      navigationRailIndex = index;
    });
  }

  /// Triggers on menu button pressed
  void onMenuButtonPressed() {
    showDialog(
      context: context,
      builder: (context) => MainMenuDialog(
        onRefreshPressed: refreshAll,
      ),
    );
  }

  /// Triggers on transaction created
  void onTransactionCreated(Transaction? transaction) {
    if (transaction != null) {
      refresh();
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
    refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = ScreenPlanner(context).isSidePanelVisible;
    return Scaffold(
      appBar: AppBar(
        title: const Text("MyFinance"),
        centerTitle: !isWide,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: onMenuButtonPressed,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () => showSearch(
              context: context,
              delegate: SearchPage(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWide)
              NavigationRail(
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                  child: TransactionAddButton(
                    onFinish: onTransactionCreated,
                  ),
                ),
                destinations: List.generate(railDestinations.length, (index) => NavigationRailDestination(
                  icon: railDestinations[index].icon,
                  selectedIcon: railDestinations[index].selectedIcon,
                  label: Text(railDestinations[index].label),
                )),
                selectedIndex: navigationRailIndex,
                onDestinationSelected: onNavigationIndexChanged,
                labelType: NavigationRailLabelType.all,
              )
            ,
            Expanded(
              child: IndexedStack(
                index: navigationRailIndex,
                children: [
                  const HomeFragment(),
                  AccountsFragment(
                    accounts: ref.watch(_filteredAccounts),
                    onItemTap: (account) => openPage(FinanceRoutePath(FinanceRoutePath.accounts.path, account.pid)),
                  ),
                  PaymentsFragment(
                    payments: ref.watch(_filteredPayments),
                    onItemTap: (payment) => openPage(FinanceRoutePath(FinanceRoutePath.payments.path, payment.pid)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWide ? null : BottomNavigationBar(
        currentIndex: navigationBarIndex,
        onTap: onNavigationIndexChanged,
        items: List.generate(barDestinations.length, (index) => BottomNavigationBarItem(
          icon: barDestinations[index].icon,
          activeIcon: barDestinations[index].selectedIcon,
          label: barDestinations[index].label,
        )),
      ),
      floatingActionButton: isWide ? null : TransactionAddButton(
        onFinish: onTransactionCreated,
      ),
    );
  }
}

class _NavigationDestinations {

  final Icon icon;

  final Icon selectedIcon;

  final String label;

  _NavigationDestinations({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}