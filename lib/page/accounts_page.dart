import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/fragment/account_details_fragment.dart';
import 'package:my_finance/fragment/accounts_fragment.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/page/account_details_page.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

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

  /// Triggers on [Account] selected
  ///
  /// If [transactionVisible] is `true`, show transactions on right side,
  /// otherwise, open [AccountDetailsPage]
  void onAccountSelected(Account account) {
    if (transactionsVisible) {
      selected = account;
      setState(() {});
    } else {
      openPage(AccountDetailsPage(pid: account.pid));
    }
  }

  /// Value of right side panel is visible or not
  bool get transactionsVisible {
    final int number = InterfaceConstructor.panelNumber(context);
    return number == 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width/(transactionsVisible ? 2 : 1);
    final account = selected ?? Account.unknown;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.pageAccounts.tr()),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: width,
            child: AccountsFragment(
              onItemTap: onAccountSelected,
              onEditFinish: (account) => setState(() {
                selected = account;
              }),
            ),
          ),
          Visibility(
            visible: transactionsVisible,
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
                          condition: {
                            Transaction.keyAccountID: account.pid,
                          },
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
    );
  }
}