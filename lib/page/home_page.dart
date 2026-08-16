import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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

int _compareNullableValues(Object? first, Object? second) {
  if (identical(first, second)) {
    return 0;
  }
  if (first == null) {
    return 1;
  }
  if (second == null) {
    return -1;
  }
  if (first.runtimeType == second.runtimeType && first is Comparable) {
    return first.compareTo(second);
  }
  return first.toString().compareTo(second.toString());
}

final _filteredAccounts = Provider<List<Account>>((ref) {
  final min = ref.watch(_minPriorityFilter);
  final max = ref.watch(_maxPriorityFilter);
  final sort = ref.watch(_sortFilter);
  final list = ref.watch(provider.accounts);
  List<Account> result = list.where((account) {
    return account.priority >= min &&
        account.priority <= max &&
        !account.deleted;
  }).toList();
  if (Account.unknown.map.containsKey(sort)) {
    result.sort(
      (a1, a2) => _compareNullableValues(a1.map[sort], a2.map[sort]),
    );
  }
  return result;
});

final _filteredPayments = Provider<List<Payment>>((ref) {
  final min = ref.watch(_minPriorityFilter);
  final max = ref.watch(_maxPriorityFilter);
  final sort = ref.watch(_sortFilter);
  final list = ref.watch(provider.payments);
  List<Payment> result = list.where((payment) {
    return payment.priority >= min &&
        payment.priority <= max &&
        !payment.deleted;
  }).toList();
  if (Payment.unknown.map.containsKey(sort)) {
    result.sort(
      (a1, a2) => _compareNullableValues(a1.map[sort], a2.map[sort]),
    );
  }
  return result;
});

final _minPriorityFilter =
    StateNotifierProvider<ValueStateNotifier<int>, int>((ref) {
  return ValueStateNotifier<int>(0);
});

final _maxPriorityFilter =
    StateNotifierProvider<ValueStateNotifier<int>, int>((ref) {
  return ValueStateNotifier<int>(1000);
});

final _sortFilter =
    StateNotifierProvider<ValueStateNotifier<String>, String>((ref) {
  return ValueStateNotifier<String>(ModelKeys.keyUuid);
});

/// Hosts the main finance tabs and responsive navigation controls.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    super.key,
    required this.router,
    this.index = 0,
    required this.onIndexChanged,
  });

  /// Router used for tab and detail navigation.
  final FinanceRouterDelegate router;

  /// Initially selected navigation destination.
  final int index;

  /// Called when the selected destination changes.
  final ValueChanged<int> onIndexChanged;

  @override
  ConsumerState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const String _tag = "HomePage";

  final List<_NavigationDestinations> railDestinations = [
    _NavigationDestinations(
      icon: const Icon(Icons.explore_outlined),
      selectedIcon: const Icon(Icons.explore),
      label: LocaleKeys.home.tr(),
      route: RoutePath.home,
    ),
    _NavigationDestinations(
      icon: const Icon(Icons.folder_copy_outlined),
      selectedIcon: const Icon(Icons.folder_copy),
      label: LocaleKeys.account.plural(1),
      route: FinanceRoutePath.accounts,
    ),
    _NavigationDestinations(
      icon: const Icon(Icons.payments_outlined),
      selectedIcon: const Icon(Icons.payments),
      label: LocaleKeys.payment.plural(1),
      route: FinanceRoutePath.payments,
    ),
  ];

  List<_NavigationDestinations> get barDestinations {
    final List<_NavigationDestinations> list = [];
    for (int i = 0; i < railDestinations.length; i++) {
      list.add(railDestinations[convertNavigationIndex(i)]);
    }
    return list;
  }

  /// Selected navigation-rail destination index.
  int navigationRailIndex = 0;

  /// Selected bottom-navigation destination index.
  int get navigationBarIndex => convertNavigationIndex(navigationRailIndex);

  /// Navigates to [path].
  void setNewRoute(RoutePath path) {
    widget.router.setNewRoutePath(path);
  }

  /// Starts login when no valid user is available.
  Future<void> tryLogin() async {
    if (!ref.watch(provider.currentUser).user.isValid) {
      provider.login(ref, load);
    }
  }

  /// Loads initial finance models and preferences after login.
  void load() async {
    if (!mounted) {
      Log.w(_tag, "Unable to load initial date due to state disposed");
      return;
    }
    Log.i(_tag, "Request initial user data");
    provider.appendAccounts(ref);
    provider.fetchPayments(ref);
    provider.fetchCategories(ref);
    provider.fetchCurrencies(ref);
    pullPreferences(ref, provider.corePreferences);
    pullPreferences(ref, provider.financePreference);
    fetchTransaction();
  }

  /// Appends transactions around the current month.
  void fetchTransaction() async {
    // Query a window that covers summary and detail cards.
    final now = DateTime.now();
    provider.appendTransactions(ref, {
      ModelKeys.keyPaidDate: {
        ApiQuery.keyQueryRangeBegin:
            DateTime(now.year, now.month - 3, 1).toIso8601String(),
        ApiQuery.keyQueryRangeEnd:
            DateTime(now.year, now.month + 2, 0).toIso8601String(),
      }
    });
  }

  /// Converts between rail and bottom-navigation indices.
  int convertNavigationIndex(int index) {
    if (index == 0) {
      return 1;
    } else if (index == 1) {
      return 0;
    }
    return index;
  }

  /// Updates navigation state for the selected rail index.
  void onNavigationIndexChanged(int index) {
    setState(() {
      navigationRailIndex = index;
    });
    setNewRoute(railDestinations[index].route);
    widget.onIndexChanged(index);
  }

  /// Opens the main menu dialog.
  void onMenuButtonPressed() {
    showDialog(
      context: context,
      builder: (context) => MainMenuDialog(
        router: widget.router,
        onRefreshPressed: load,
      ),
    );
  }

  /// Opens the selected account detail route.
  void onAccountPressed(Account account) {
    setNewRoute(
        FinanceRoutePath(FinanceRoutePath.accounts.path, uuid: account.uuid));
  }

  /// Opens the selected payment detail route.
  void onPaymentPressed(Payment payment) {
    setNewRoute(
        FinanceRoutePath(FinanceRoutePath.payments.path, uuid: payment.uuid));
  }

  /// Get [GridView] cross axis count
  ///
  /// Value is always bigger than `0`
  int getCrossAxisCount(BuildContext context) =>
      ScreenPlanner(context).panelNumber;

  /// Returns the responsive group-card aspect ratio.
  double getChildAspectRatio(BuildContext context) {
    return (MediaQuery.of(context).size.width / getCrossAxisCount(context)) /
        GroupCard.height;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await tryLogin();
    });
    navigationRailIndex = widget.index;
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = ScreenPlanner(context).isSidePanelVisible;
    final accounts = ref.watch(_filteredAccounts);
    final payments = ref.watch(_filteredPayments);
    const iconName = 'assets/icon/icon-full.png';
    final user = ref.watch(provider.currentUser).user;
    return Scaffold(
      appBar: AppBar(
        title: AppTitle(
          iconName: iconName,
          isWide: isWide,
          title: "MyFinance",
        ),
        centerTitle: !isWide,
        leading: isWide
            ? null
            : IconButton(
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
                leading: const Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 16),
                  child: TransactionAddButton(),
                ),
                destinations: List.generate(
                    railDestinations.length,
                    (index) => NavigationRailDestination(
                          icon: railDestinations[index].icon,
                          selectedIcon: railDestinations[index].selectedIcon,
                          label: Text(railDestinations[index].label),
                        )),
                trailing: Expanded(
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      icon: UserIcon(user, size: 32),
                      onPressed: onMenuButtonPressed,
                    ),
                  ),
                ),
                selectedIndex: navigationRailIndex,
                onDestinationSelected: onNavigationIndexChanged,
                labelType: NavigationRailLabelType.all,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
                child: IndexedStack(
                  index: navigationRailIndex,
                  children: [
                    const HomeFragment(),
                    AccountsFragment(
                      accounts: accounts,
                      onItemTap: onAccountPressed,
                    ),
                    PaymentsFragment(
                      payments: payments,
                      onItemTap: onPaymentPressed,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : Theme(
              data: Theme.of(context).copyWith(
                splashFactory: NoSplash.splashFactory,
              ),
              child: BottomNavigationBar(
                currentIndex: convertNavigationIndex(navigationRailIndex),
                onTap: (index) {
                  return onNavigationIndexChanged(
                      convertNavigationIndex(index));
                },
                items: List.generate(
                    barDestinations.length,
                    (index) => BottomNavigationBarItem(
                          icon: barDestinations[index].icon,
                          activeIcon: barDestinations[index].selectedIcon,
                          label: barDestinations[index].label,
                        )),
              ),
            ),
      floatingActionButton: isWide ? null : const TransactionAddButton(),
    );
  }
}

/// Associates navigation icons and labels with an application route.
class _NavigationDestinations {
  final Icon icon;

  final Icon selectedIcon;

  final String label;

  final RoutePath route;

  _NavigationDestinations({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}
