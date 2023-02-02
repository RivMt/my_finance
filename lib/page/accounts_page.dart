import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/fragment/accounts_fragment.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {

  /// Selected [Account]
  Account? selected;

  /// Triggers on [Account] selected
  void onAccountSelected(Account account) {
    setState(() {
      selected = account;
    });
  }

  /// Calculate flex of transactions fragment at right side
  ///
  /// It returns `0` when [selected] is `null` or width is lesser than `0.8` * height
  double transactionsWidth(BuildContext context) {
    // Return 0 on no selection
    if (selected == null) {
      return 0;
    }
    final double width, height;
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    if (width >= 0.8*height) {
      if (width >= 1.6*height) {
        return width - 0.8*height;
      }
      return width/2;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.pageAccounts.tr()),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width - transactionsWidth(context),
            child: AccountsFragment(
              onItemTap: onAccountSelected,
            ),
          ),
          SizedBox(
            width: transactionsWidth(context),
            child: TransactionsFragment(
              condition: {
                FinanceModel.keyPid: (selected == null ? -1 : selected!.pid),
              },
            ),
          ),
        ],
      ),
    );
  }
}