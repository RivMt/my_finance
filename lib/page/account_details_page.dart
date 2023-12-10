import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/fragment/account_edit_fragment.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

final _filteredTransactions = Provider<List<Transaction>>((ref) {
  final date = ref.watch(_dateFilter);
  final begin = DateTime(date.year, date.month, 1);
  final end = DateTime(date.year, date.month + 1, 0);
  final sort = ref.watch(_sortFilter);
  List<Transaction> list = ref.watch(provider.transactions);
  list = list
      .where((item) => (!item.deleted && item.paidDate.compareTo(begin) == 1 && item.paidDate.compareTo(end) == -1)).toList();
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
    provider.refreshTransactions(ref, accountId: account.pid);
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
    ).then((account) {
      provider.refreshAccounts(ref);
    });
  }

  void onSortButtonPressed() {
    ref.read(_sortFilter.notifier).set(!isReverse);
  }

  void onRefreshButtonPressed() => refresh();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(account.descriptions),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showAccountEditingModal(context, account),
              )
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(200),
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.serialNumber,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            account.currency.format(account.balance),
                            style: Theme.of(context).textTheme.displayLarge,
                          )
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: Icon(isReverse ? Icons.arrow_upward_outlined : Icons.arrow_downward),
                          onPressed: onSortButtonPressed,
                          label: Text(LocaleKeys.sort.tr()),
                        ),
                        MonthPicker(
                          date: month,
                          displayText: (date) => DateFormat.yM().format(date),
                          onDateChanged: onMonthChanged,
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          onPressed: onRefreshButtonPressed,
                          label: Text(LocaleKeys.refresh.tr()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: TransactionsFragment(
              useSliver: true,
              items: transactions,
              isReverse: isReverse,
            ),
          ),
        ],
      ),
      floatingActionButton: TransactionAddButton(
        account: account,
      ),
    );
  }

}