import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/account_details_fragment.dart';
import 'package:my_finance/fragment/accounts_fragment.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({
    super.key,
    this.init,
  });

  final Account? init;

  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {

  /// Selected [Account]
  Account? selected;

  /// Open page
  void openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  /// Check page can be pop
  bool checkPageCanPop(BuildContext context) {
    if (!ScreenPlanner(context).isSidePanelVisible) {
      return selected == null;
    }
    return true;
  }

  /// Triggers on back button pressed
  void onBackButtonPressed(BuildContext context) {
    if (checkPageCanPop(context)) {
      Navigator.pop(context);
    }
    selected = null;
    setState(() {});
    return;
  }

  /// Triggers on [Account] selected
  void onAccountSelected(Account account) {
    selected = account;
    setState(() {});
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
    selected = widget.init;
  }

  @override
  Widget build(BuildContext context) {
    final width = ScreenPlanner(context).panelWidth;
    final account = selected ?? Account.unknown;
    final sideVisible = ScreenPlanner(context).isSidePanelVisible;
    return WillPopScope(
      onWillPop: () async {
        final value = checkPageCanPop(context);
        if (!value) {
          selected = null;
          setState(() {});
        }
        return value;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocaleKeys.account.plural(2)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => onBackButtonPressed(context),
          ),
        ),
        body: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Visibility(
                visible: sideVisible || account == Account.unknown,
                child: SizedBox(
                  width: width,
                  child: AccountsFragment(
                    selected: selected,
                    onItemTap: onAccountSelected,
                    onEditFinish: onAccountSelected,
                  ),
                ),
              ),
              Visibility(
                visible: sideVisible || account != Account.unknown,
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
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AccountDetailsFragment(
                              account: account,
                            ),
                            const SizedBox(height: 8,),
                            Expanded(
                              child: TransactionsFragment(
                                conditions: [{
                                  Transaction.keyAccountID: account.pid,
                                  FinanceModel.keyDeleted: false,
                                }],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: TransactionAddButton(
          onFinish: onTransactionCreated,
        ),
      ),
    );
  }
}