import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/account_details_fragment.dart';
import 'package:my_finance/fragment/accounts_fragment.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/navigator.dart';
import 'package:my_finance/page/account_details_page.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({
    super.key,
    required this.router,
    this.pid,
  });

  final RouterDelegate router;

  final int? pid;

  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {

  /// Selected [Account]
  Account? selected;

  /// Open page
  void openPage(RoutePath path) {
    widget.router.setNewRoutePath(path);
  }

  /// Triggers on [Account] selected
  ///
  /// If [transactionVisible] is `true`, show transactions on right side,
  /// otherwise, open [AccountDetailsPage]
  void onAccountSelected(Account account) {
    if (ScreenPlanner(context).isSidePanelVisible) {
      selected = account;
      setState(() {});
    } else {
      openPage(FinanceRoutePath.accounts.details(account.pid));
    }
  }

  /// Triggers on transaction created
  void onTransactionCreated(Transaction? transaction) {
    if (transaction != null) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.pid != null) {
      selected = Account({
        FinanceModel.keyPid: widget.pid,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = ScreenPlanner(context).panelWidth;
    final account = selected ?? Account.unknown;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.account.plural(2)),
      ),
      body: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Visibility(
              visible: ScreenPlanner(context).isSidePanelVisible || account == Account.unknown,
              child: SizedBox(
                width: width,
                child: AccountsFragment(
                  selected: selected,
                  onItemTap: onAccountSelected,
                  onEditFinish: (account) => setState(() {
                    selected = account;
                  }),
                ),
              ),
            ),
            Visibility(
              visible: ScreenPlanner(context).isSidePanelVisible || account != Account.unknown,
              child: SizedBox(
                width: width,
                child: IndexedStack(
                  index: account == Account.unknown ? 0 : 1,
                  children: [
                    // 0: No account
                    MessageBox(
                      icon: Icons.question_mark_outlined,
                      message: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
                        "object": LocaleKeys.account.plural(1),
                      }),
                    ),
                    // 1: Account details and transactions
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: AccountDetailsFragment(
                            account: account,
                          ),
                        ),
                        Expanded(
                          child: TransactionsFragment(
                            conditions: [{
                              Transaction.keyAccountID: account.pid,
                              FinanceModel.keyDeleted: false,
                            }],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Visibility(
        visible: ScreenPlanner(context).isSidePanelVisible,
        child: TransactionAddButton(
          onFinish: onTransactionCreated,
        ),
      ),
    );
  }
}