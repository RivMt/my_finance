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
  final sort = ref.watch(_sortFilter);
  final list = ref.watch(provider.accounts);
  List<Account> result = list.where((account) => account.deleted).toList();
  if (Account.unknown.map.containsKey(sort)) {
    result.sort((a1, a2) =>
        (a1.map[sort] as Comparable).compareTo(a2.map[sort]));
  }
  return result;
});

final _filteredPayments = Provider<List<Payment>>((ref) {
  final sort = ref.watch(_sortFilter);
  final list = ref.watch(provider.payments);
  List<Payment> result = list.where((payment) => payment.deleted).toList();
  if ( Payment.unknown.map.containsKey(sort)) {
    result.sort((a1, a2) =>
        (a1.map[sort] as Comparable).compareTo(a2.map[sort]));
  }
  return result;
});

final _sortFilter = StateNotifierProvider<ModelState<String>, String>((ref) {
  return ModelState<String>(ref, ModelKeys.keyLastUsed);
});

class RestoreItemsPage extends ConsumerStatefulWidget {

  static const String routeTrash = "/trash";

  const RestoreItemsPage({
    super.key,
  });

  @override
  ConsumerState createState() => _RestoreItemsPageState();
}

class _RestoreItemsPageState extends ConsumerState<RestoreItemsPage> with TickerProviderStateMixin {

  late final TabController tabController;

  final PageController pageController = PageController(
    initialPage: 0,
  );

  final List<Map<String, dynamic>> conditions = [{
    ModelKeys.keyDeleted: true,
  }];

  /// Restore [item]
  Future<bool> restoreItem<T extends WalletItem>(T item) async {
    item.deleted = false;
    switch(T) {
      case Account: return await provider.updateAccount(ref, item as Account);
      case Payment: return await provider.updatePayment(ref, item as Payment);
      default: throw UnimplementedError();
    }
  }

  /// Change index of [pageController] by index of [tabController]
  void onTabChanged(int index) {
    setState(() {
      pageController.jumpToPage(index);
    });
  }

  /// Restore [item] when opened [SnackBar] closed successfully
  void onItemTap<T extends WalletItem>(T item) {
    restoreItem<T>(item);
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
        title: Text(LocaleKeys.trashCan.tr()),
        bottom: TabBar(
          controller: tabController,
          tabs: [
            Tab(text: LocaleKeys.account.plural(1),),
            Tab(text: LocaleKeys.payment.plural(1),),
          ],
          splashBorderRadius: const BorderRadius.all(Radius.circular(8)),
          onTap: onTabChanged,
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // 0: Accounts
              AccountsFragment(
                accounts: ref.watch(_filteredAccounts).reversed.toList(),
                hideCreateButton: true,
                hideHeader: true,
                onItemTap: (item) => onItemTap<Account>(item),
              ),
              // 1: Payments
              PaymentsFragment(
                payments: ref.watch(_filteredPayments).reversed.toList(),
                hideCreateButton: true,
                paymentsConditions: conditions,
                onItemTap: (item) => onItemTap<Payment>(item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    tabController.dispose();
    pageController.dispose();
  }
}