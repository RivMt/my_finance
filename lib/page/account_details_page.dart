import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/fragment/account_edit_fragment.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/fragment/wallet_item_details_fragment.dart';
import 'package:my_finance/local_provider.dart' as local_provider;

final _filteredTransactions = Provider<List<Transaction>>((ref) {
  final date = ref.watch(_dateFilter);
  final begin = DateTime(date.year, date.month, 1);
  final end = DateTime(date.year, date.month + 1, 1);
  final sort = ref.watch(_sortFilter);
  final account = ref.watch(local_provider.selectedAccount);
  List<Transaction> list = ref.watch(provider.transactions);
  list = list.where((item) {
    return !item.deleted
        && item.calculatedDate.compareTo(begin) >= 0
        && item.calculatedDate.compareTo(end) == -1
        && item.accountId == account;
  }).toList();
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
  });

  @override
  ConsumerState createState() => _AccountDetailsPageState();

}

class _AccountDetailsPageState extends ConsumerState<AccountDetailsPage> {

  List<Transaction> get transactions => ref.watch(_filteredTransactions);

  bool get isReverse => ref.watch(_sortFilter);

  DateTime get month => ref.watch(_dateFilter);

  set month(DateTime value) {
    ref.read(_dateFilter.notifier).set(value);
  }

  void refresh() {
    final account = ref.watch(local_provider.selectedAccount);
    provider.refreshAccounts(ref);
    provider.fetchTransactions(ref, [{
      ModelKeys.keyAccountID: account,
    }]);
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
    final account = ref.watch(provider.accounts).firstWhere((element) => element.pid == ref.watch(local_provider.selectedAccount));
    return Scaffold(
      appBar: AppBar(
        title: Text(account.descriptions),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showAccountEditingModal(context, account),
          ),
        ],
      ),
      body: WalletItemDetailsFragment<Account>(
        item: account,
        content: account.balance,
        transactions: transactions,
        month: month,
        isReverse: isReverse,
        sortByCalculatedDate: true,
        onMonthChanged: onMonthChanged,
        onSortButtonPressed: onSortButtonPressed,
        onRefreshButtonPressed: onRefreshButtonPressed,
        onTransactionEdit: (item) => refresh(),
      ),
      floatingActionButton: TransactionAddButton(
        account: account,
        onFinish: (item) => refresh(),
      ),
    );
  }

  @override
  void dispose() {
    month = DateTime.now();
    super.dispose();
  }
}