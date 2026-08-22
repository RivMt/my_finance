import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/modal/account_edit_modal.dart';
import 'package:my_finance/modal/transfer_edit_modal.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/fragment/wallet_item_details_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

final _uuid = StateNotifierProvider<ValueStateNotifier<String>, String>((ref) {
  return ValueStateNotifier(Account.unknown.uuid);
});

final _account = Provider<Account>((ref) {
  final accounts = ref.watch(provider.accounts);
  final uuid = ref.watch(_uuid);
  return accounts.firstWhere((element) => element.uuid == uuid,
      orElse: () => Account.unknown);
});

final _filteredTransactions = Provider<List<Transaction>>((ref) {
  final date = ref.watch(_dateFilter);
  final begin = DateTime(date.year, date.month, 1);
  final end = DateTime(date.year, date.month + 1, 1);
  final sort = ref.watch(_sortFilter);
  final account = ref.watch(_account);
  List<Transaction> list = ref.watch(provider.transactions);
  list = list.where((item) {
    return !item.deleted &&
        item.calculatedDate.compareTo(begin) >= 0 &&
        item.calculatedDate.compareTo(end) == -1 &&
        item.accountId == account.uuid;
  }).toList();
  if (sort) {
    list = list.reversed.toList();
  }
  return list;
});

final _dateFilter =
    StateNotifierProvider<ValueStateNotifier<DateTime>, DateTime>((ref) {
  return ValueStateNotifier<DateTime>(
      DateTime(DateTime.now().year, DateTime.now().month, 1));
});

final _sortFilter =
    StateNotifierProvider<ValueStateNotifier<bool>, bool>((ref) {
  return ValueStateNotifier<bool>(false);
});

/// Displays an account balance and its monthly transactions.
class AccountDetailsPage extends ConsumerStatefulWidget {
  const AccountDetailsPage({
    super.key,
    required this.uuid,
  });

  /// UUID of the account to display.
  final String uuid;

  @override
  ConsumerState createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends ConsumerState<AccountDetailsPage> {
  /// Whether transactions are shown in reverse order.
  bool get isReverse => ref.watch(_sortFilter);

  /// Month currently displayed.
  DateTime get month => ref.watch(_dateFilter);

  set month(DateTime value) {
    ref.read(_dateFilter.notifier).set(value);
  }

  /// Appends transactions for the current account.
  Future<void> appendTransactions() async {
    final uuid = ref.watch(_uuid);
    provider.appendTransactions(ref, {
      ModelKeys.keyAccountId: uuid,
    });
  }

  /// Shows the account editing modal.
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

  /// Shows a transfer modal with the current account as its source or target.
  void showTransferEditingModal(
    BuildContext context, {
    Account? accountFrom,
    Account? accountTo,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) => Wrap(
        children: [
          TransferEditModal(
            accountFrom: accountFrom,
            accountTo: accountTo,
          ),
        ],
      ),
    ).then((_) => appendTransactions());
  }

  /// Changes the month and requests account transactions.
  void onMonthChanged(DateTime value) {
    month = value;
    appendTransactions();
  }

  /// Toggles transaction ordering.
  void onSortButtonPressed() {
    ref.read(_sortFilter.notifier).set(!isReverse);
  }

  /// Refreshes account transactions.
  Future<void> onRefreshButtonPressed() => appendTransactions();

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
    final fillTransferButtonWidth = ScreenPlanner(context).panelNumber == 1;
    final sendButton = FilledButton.tonalIcon(
      icon: const Icon(Icons.arrow_upward_outlined),
      label: Text(LocaleKeys.transferFrom.tr()),
      onPressed: account == Account.unknown
          ? null
          : () => showTransferEditingModal(
                context,
                accountFrom: account,
              ),
    );
    final receiveButton = FilledButton.tonalIcon(
      icon: const Icon(Icons.arrow_downward_outlined),
      label: Text(LocaleKeys.transferTo.tr()),
      onPressed: account == Account.unknown
          ? null
          : () => showTransferEditingModal(
                context,
                accountTo: account,
              ),
    );
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
        headerActions: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              if (fillTransferButtonWidth)
                Expanded(child: sendButton)
              else
                sendButton,
              const SizedBox(width: 8),
              if (fillTransferButtonWidth)
                Expanded(child: receiveButton)
              else
                receiveButton,
            ],
          ),
        ),
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
