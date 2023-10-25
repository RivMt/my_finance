import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/fragment/accounts_fragment.dart';
import 'package:my_finance/fragment/payments_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

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
  return ModelState<int>(ref, -1000);
});

final _maxPriorityFilter = StateNotifierProvider<ModelState<int>, int>((ref) {
  return ModelState<int>(ref, -1);
});

final _sortFilter = StateNotifierProvider<ModelState<String>, String>((ref) {
  return ModelState<String>(ref, ModelKeys.keyLastUsed);
});

enum RestoreItemType {
  visible,
  deleted;

  String get title {
    if (this == RestoreItemType.deleted) {
      return LocaleKeys.trashCan.tr();
    }
    return LocaleKeys.hiddenItems.tr();
  }

  static RestoreItemType getByName(String name) {
    for(RestoreItemType type in RestoreItemType.values) {
      if (type.name == name) {
        return type;
      }
    }
    return RestoreItemType.visible;
  }
}

class RestoreItemsPage extends ConsumerStatefulWidget {

  static const String routeTrash = "/trash";

  static const String routeInvisible = "/visible";

  const RestoreItemsPage({
    super.key,
    required this.type,
  });

  final RestoreItemType type;

  @override
  ConsumerState createState() => _RestoreItemsPageState();
}

class _RestoreItemsPageState extends ConsumerState<RestoreItemsPage> with TickerProviderStateMixin {

  late final TabController tabController;

  List<Map<String, dynamic>> get conditions {
    if (widget.type == RestoreItemType.deleted) {
      return const [{
        ModelKeys.keyDeleted: true,
      }];
    } else {
      return const [{
        ModelKeys.keyPriority: {
          "max": -1
        },
      }];
    }
  }

  /// Restore [item] when opened [SnackBar] closed successfully
  void onItemTap<T extends WalletItem>(BuildContext context, T item) {
    final snackBar = SnackBar(
      content: Text(LocaleKeys.msgItemRestored.tr(args: [item.descriptions])),
      action: SnackBarAction(
        label: LocaleKeys.undo.tr(),
        onPressed: () {},
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((value) async {
      if (value != SnackBarClosedReason.action) {
        if (widget.type == RestoreItemType.deleted) {
          item.deleted = false;
        } else {
          item.priority = 0;
        }
        await ApiClient().update<T>([item.map]);
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Tab controller
    tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type.title),
        bottom: TabBar(
          controller: tabController,
          tabs: [
            Tab(text: LocaleKeys.account.plural(1),),
            Tab(text: LocaleKeys.payment.plural(1),),
          ],
          onTap: (index) => setState(() {}),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: ScreenPlanner(context).panelWidth,
            child: IndexedStack(
              index: tabController.index,
              children: [
                // 0: Accounts
                AccountsFragment(
                  accounts: ref.watch(_filteredAccounts).reversed.toList(),
                  hideCreateButton: true,
                  hideHeader: true,
                  onItemTap: (item) => onItemTap<Account>(context, item),
                ),
                // 1: Payments
                PaymentsFragment(
                  payments: ref.watch(_filteredPayments).reversed.toList(),
                  hideCreateButton: true,
                  paymentsConditions: conditions,
                  onItemTap: (item) => onItemTap<Payment>(context, item),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}