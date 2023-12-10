import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/fragment/payment_edit_fragment.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/fragment/wallet_item_details_fragment.dart';

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

final _totalExpense = Provider<Decimal>((ref) {
  final date = ref.watch(_dateFilter);
  final begin = DateTime(date.year, date.month, 1);
  final end = DateTime(date.year, date.month + 1, 0);
  List<Transaction> list = ref.watch(provider.transactions);
  list = list
      .where((item) => (!item.deleted && item.paidDate.compareTo(begin) == 1 && item.paidDate.compareTo(end) == -1)).toList();
  return list.fold<Decimal>(Decimal.zero, (Decimal value, item) => value + item.amount * (item.type == TransactionType.expense ? Decimal.one : Decimal.fromInt(-1)));
});

final _dateFilter = StateNotifierProvider<ModelState<DateTime>, DateTime>((ref) {
  return ModelState<DateTime>(ref, DateTime(DateTime.now().year, DateTime.now().month, 1));
});

final _sortFilter = StateNotifierProvider<ModelState<bool>, bool>((ref) {
  return ModelState<bool>(ref, false);
});

class PaymentDetailsPage extends ConsumerStatefulWidget {

  const PaymentDetailsPage({
    super.key,
    required this.pid,
  });

  final int pid;

  @override
  ConsumerState createState() => _PaymentDetailsPageState();

}

class _PaymentDetailsPageState extends ConsumerState<PaymentDetailsPage> {

  Payment get payment => ref.watch(provider.payments).firstWhere((payment) => payment.pid == widget.pid, orElse: () => Payment.unknown);

  List<Transaction> get transactions => ref.watch(_filteredTransactions);

  bool get isReverse => ref.watch(_sortFilter);

  DateTime get month => ref.watch(_dateFilter);

  set month(DateTime value) {
    ref.read(_dateFilter.notifier).set(value);
  }

  void refresh() {
    provider.refreshTransactions(ref, paymentId: payment.pid);
  }

  void onMonthChanged(DateTime value) {
    month = value;
    refresh();
  }

  /// Show payment editing modal
  void showPaymentEditingModal(BuildContext context, [Payment? payment]) async {
    Payment? editing = payment;
    showModalBottomSheet<Payment>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) {
        return Wrap(
          children: [
            PaymentEditFragment(
              base: editing,
              onFinish: (payment) {
                Navigator.pop(context, payment);
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
      body: WalletItemDetailsFragment<Payment>(
        item: payment,
        content: ref.watch(_totalExpense),
        transactions: transactions,
        month: month,
        onEditButtonPressed: () => showPaymentEditingModal(context, payment),
        onMonthChanged: onMonthChanged,
        onSortButtonPressed: onSortButtonPressed,
        onRefreshButtonPressed: onRefreshButtonPressed,
        isReverse: isReverse,
      ),
      floatingActionButton: TransactionAddButton(
        payment: payment,
      ),
    );
  }

}