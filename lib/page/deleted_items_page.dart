import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/accounts_fragment.dart';
import 'package:my_finance/fragment/payments_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class DeletedItemsPage extends StatefulWidget {
  const DeletedItemsPage({super.key});

  @override
  _DeletedItemsPageState createState() => _DeletedItemsPageState();
}

class _DeletedItemsPageState extends State<DeletedItemsPage> with TickerProviderStateMixin {

  late final TabController tabController;

  /// Restore [item] when opened [SnackBar] closed successfully
  void onItemTap<T extends FinanceModel>(BuildContext context, T item) {
    final snackBar = SnackBar(
      content: Text(LocaleKeys.msgItemRestored.tr(args: [item.descriptions])),
      action: SnackBarAction(
        label: LocaleKeys.undo.tr(),
        onPressed: () {},
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((value) async {
      if (value != SnackBarClosedReason.action) {
        item.deleted = false;
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
        title: Text(LocaleKeys.trashCan.tr()),
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
        child: SizedBox(
          width: ScreenPlanner(context).panelWidth,
          child: IndexedStack(
            index: tabController.index,
            children: [
              // 0: Accounts
              AccountsFragment(
                hideCreateButton: true,
                hideHeader: true,
                conditions: const [{
                  FinanceModel.keyDeleted: true,
                }],
                onItemTap: (item) => onItemTap<Account>(context, item),
              ),
              // 1: Payments
              PaymentsFragment(
                hideCreateButton: true,
                paymentsConditions: const [{
                  FinanceModel.keyDeleted: true,
                }],
                onItemTap: (item) => onItemTap<Payment>(context, item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}