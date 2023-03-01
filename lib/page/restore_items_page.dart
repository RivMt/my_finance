import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/accounts_fragment.dart';
import 'package:my_finance/fragment/payments_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

enum RestoreItemType {
  visible,
  deleted,
}

class RestoreItemsPage extends StatefulWidget {
  const RestoreItemsPage({
    super.key,
    required this.type,
    required this.title,
  });

  final String title;

  final RestoreItemType type;

  @override
  State createState() => _RestoreItemsPageState();
}

class _RestoreItemsPageState extends State<RestoreItemsPage> with TickerProviderStateMixin {

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
        title: Text(widget.title),
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
                  hideCreateButton: true,
                  hideHeader: true,
                  conditions: conditions,
                  onItemTap: (item) => onItemTap<Account>(context, item),
                ),
                // 1: Payments
                PaymentsFragment(
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