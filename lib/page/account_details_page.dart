import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/modal/account_edit_modal.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/fragment/wallet_item_details_fragment.dart';

final _uuid = StateNotifierProvider<ValueStateNotifier<String>, String>((ref) {
  return ValueStateNotifier(ref, Account.unknown.uuid);
});

final _account = Provider<Account>((ref) {
  final accounts = ref.watch(provider.accounts);
  final uuid = ref.watch(_uuid);
  return accounts.firstWhere((element) => element.uuid == uuid, orElse: () => Account.unknown);
});

final _filteredTransactions = Provider<List<Transaction>>((ref) {
  final date = ref.watch(_dateFilter);
  final begin = DateTime(date.year, date.month, 1);
  final end = DateTime(date.year, date.month + 1, 1);
  final sort = ref.watch(_sortFilter);
  final account = ref.watch(_account);
  List<Transaction> list = ref.watch(provider.transactions);
  list = list.where((item) {
    return !item.deleted
        && item.calculatedDate.compareTo(begin) >= 0
        && item.calculatedDate.compareTo(end) == -1
        && item.accountId == account.uuid;
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
    required this.uuid,
  });

  final String uuid;

  @override
  ConsumerState createState() => _AccountDetailsPageState();

}

class _AccountDetailsPageState extends ConsumerState<AccountDetailsPage> {

  bool get isReverse => ref.watch(_sortFilter);

  DateTime get month => ref.watch(_dateFilter);

  set month(DateTime value) {
    ref.read(_dateFilter.notifier).set(value);
  }

  Future<void> fetchTransactions() async {
    final uuid = ref.watch(_uuid);
    provider.fetchTransactions(ref, {
      ModelKeys.keyAccountId: uuid,
    });
  }

  /// Show account editing modal
  void showAccountEditingModal(BuildContext context, [Account? account]) async {
    showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) {
        return Wrap(
          children: [
            AccountEditModal(account),
          ],
        );
      },
    );
  }

  void onMonthChanged(DateTime value) {
    month = value;
    fetchTransactions();
  }

  void onSortButtonPressed() {
    ref.read(_sortFilter.notifier).set(!isReverse);
  }

  Future<void> onRefreshButtonPressed() => fetchTransactions();


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      ref.read(_uuid.notifier).set(widget.uuid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(_account);
    final transactions = ref.watch(_filteredTransactions);
    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
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
      ),
      floatingActionButton: TransactionAddButton(
        account: account,
      ),
    );
  }
}