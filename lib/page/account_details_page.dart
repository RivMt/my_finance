import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/fragment/account_edit_fragment.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/fragment/wallet_item_details_fragment.dart';

final _filteredTransactions = Provider<List<Transaction>>((ref) {
  final date = ref.watch(_dateFilter);
  final begin = DateTime(date.year, date.month, 1);
  final end = DateTime(date.year, date.month + 1, 1);
  final sort = ref.watch(_sortFilter);
  List<Transaction> list = ref.watch(provider.transactions);
  list = list
      .where((item) => (!item.deleted && item.paidDate.compareTo(begin) >= 0 && item.paidDate.compareTo(end) == -1)).toList();
  if (sort) {
    list = list.reversed.toList();
  }
  return list;
});

final _dateFilter = StateNotifierProvider<ModelState<DateTime>, DateTime>((ref) {
  return ModelState<DateTime>(ref, DateTime(DateTime.now().year, DateTime.now().month, 1));
});

final _sortFilter = StateNotifierProvider<ModelState<bool>, bool>((ref) {
  return ModelState<bool>(ref, false);
});

class AccountDetailsPage extends ConsumerStatefulWidget {

  const AccountDetailsPage({
    super.key,
    required this.pid,
  });

  final int pid;

  @override
  ConsumerState createState() => _AccountDetailsPageState();

}

class _AccountDetailsPageState extends ConsumerState<AccountDetailsPage> {

  Account get account => ref.watch(provider.accounts).firstWhere((account) => account.pid == widget.pid, orElse: () => Account.unknown);

  List<Transaction> get transactions => ref.watch(_filteredTransactions);

  bool get isReverse => ref.watch(_sortFilter);

  DateTime get month => ref.watch(_dateFilter);

  set month(DateTime value) {
    ref.read(_dateFilter.notifier).set(value);
  }

  void refresh() {
    provider.fetchTransactions(ref, [{
      ModelKeys.keyAccountID: account.pid,
    }]);
    provider.refreshAccounts(ref);
  }

  void onMonthChanged(DateTime value) {
    month = value;
    refresh();
  }

  /// Show account editing modal
  void showAccountEditingModal(BuildContext context, [Account? account]) async {
    Account? editing = account;
    showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) {
        return Wrap(
          children: [
            AccountEditFragment(
              base: editing,
              onFinish: (account) {
                Navigator.pop(context, account);
              },
            ),
          ],
        );
      },
    ).then((item) {
      refresh();
    });
  }

  void onSortButtonPressed() {
    ref.read(_sortFilter.notifier).set(!isReverse);
  }

  void onRefreshButtonPressed() => refresh();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WalletItemDetailsFragment<Account>(
        item: account,
        content: account.balance,
        transactions: transactions,
        month: month,
        onEditButtonPressed: () => showAccountEditingModal(context, account),
        onMonthChanged: onMonthChanged,
        onSortButtonPressed: onSortButtonPressed,
        onRefreshButtonPressed: onRefreshButtonPressed,
        isReverse: isReverse,
      ),
      floatingActionButton: TransactionAddButton(
        account: account,
        onFinish: (item) => refresh(),
      ),
    );
  }

}