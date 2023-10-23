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
import 'package:my_finance/page/search_page.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/preference_keys.dart';

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

  static const String route = "/";

  const HomePage({super.key});

  @override
  ConsumerState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {

  static const String _tag = "HomePage";

  final client = ApiClient();

  final List<_NavigationDestinations> destinations = [
    _NavigationDestinations(
      icon: const Icon(Icons.home_filled),
      selectedIcon: const Icon(Icons.home_filled),
      label: LocaleKeys.home,
    ),
    _NavigationDestinations(
      icon: const Icon(Icons.folder_outlined),
      selectedIcon: const Icon(Icons.folder),
      label: LocaleKeys.account.plural(1),
    ),
    _NavigationDestinations(
      icon: const Icon(Icons.payment_outlined),
      selectedIcon: const Icon(Icons.payment),
      label: LocaleKeys.payment.plural(1),
    ),
  ];

  int navigationIndex = 0;

  void onNavigationIndexChanged(int index) {
    navigationIndex = index;
    setState(() {});
  }

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
        onLoginRequired: () => openPage(
          const LoginPage(),
              (value) => refresh(),
        ),
        preferences: prefs,
      );
      // Refresh providers
      provider.refreshAccounts(ref);
      provider.refreshPayments(ref);
      provider.refreshCategories(ref);
    } on Exception catch(e) {
      Log.e(_tag, "Error: $e");
      return;
    }
    // Request
    refresh();
  }

  /// Refresh page
  void refresh() {
    provider.refreshAccounts(ref);
    provider.refreshPayments(ref);
    provider.refreshCategories(ref);
    onNavigationIndexChanged(navigationIndex);
  }

  /// Open [page]
  ///
  /// After [page] has been pop, triggers [onPageFinished] if it is not `null`.
  void openPage(Widget page, [Function(dynamic)? onPageFinished]) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page)).then((value) {
      if (onPageFinished != null) {
        onPageFinished(value);
      }
    }).then((value) {
      refresh();
    });
  }

  /// Triggers on menu button pressed
  void onMenuButtonPressed() {
    showDialog(
      context: context,
      builder: (context) => MainMenuDialog(
        onAccountButtonPressed: refresh,
        onRefreshPressed: refresh,
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
    init();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = ScreenPlanner(context).isSidePanelVisible;
    return Scaffold(
      appBar: AppBar(
        title: const Text("MyFinance"),
        centerTitle: MediaQuery.of(context).orientation == Orientation.portrait,
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
                destinations: List.generate(destinations.length, (index) => NavigationRailDestination(
                  icon: destinations[index].icon,
                  selectedIcon: destinations[index].selectedIcon,
                  label: Text(destinations[index].label),
                )),
                selectedIndex: navigationIndex,
                onDestinationSelected: onNavigationIndexChanged,
                labelType: NavigationRailLabelType.all,
              )
            ,
            Expanded(
              child: IndexedStack(
                index: navigationIndex,
                children: [
                  HomeFragment(),
                  AccountsFragment(accounts: ref.watch(_filteredAccounts),),
                  PaymentsFragment()
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWide ? null : BottomNavigationBar(
        currentIndex: navigationIndex,
        onTap: onNavigationIndexChanged,
        items: List.generate(destinations.length, (index) => BottomNavigationBarItem(
          icon: destinations[index].icon,
          activeIcon: destinations[index].selectedIcon,
          label: destinations[index].label,
        )),
      ),
      floatingActionButton: TransactionAddButton(
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