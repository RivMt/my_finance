import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/modal/payment_edit_modal.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/fragment/wallet_item_details_fragment.dart';
import 'package:my_finance/local_provider.dart' as local_provider;

const _tag = "PaymentDetailsPage";

final _filteredTransactions = Provider<List<Transaction>>((ref) {
  final date = ref.watch(_dateFilter);
  final begin = DateTime(date.year, date.month, 1);
  final end = DateTime(date.year, date.month + 1, 1);
  final sort = ref.watch(_sortFilter);
  final payment = ref.watch(local_provider.selectedPayment);
  List<Transaction> list = ref.watch(provider.transactions);
  list = list.where((item) {
    return !item.deleted
        && item.paidDate.compareTo(begin) >= 0
        && item.paidDate.compareTo(end) == -1
        && item.paymentId == payment;
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

class PaymentDetailsPage extends ConsumerStatefulWidget {

  const PaymentDetailsPage({
    super.key,
  });

  @override
  ConsumerState createState() => _PaymentDetailsPageState();

}

class _PaymentDetailsPageState extends ConsumerState<PaymentDetailsPage> {

  bool get isReverse => ref.watch(_sortFilter);

  DateTime get month => ref.watch(_dateFilter);

  set month(DateTime value) {
    ref.read(_dateFilter.notifier).set(value);
  }

  Future<void> refresh() async {
    provider.fetchTransactions(ref, [{
      ModelKeys.keyPaymentID: ref.watch(local_provider.selectedPayment),
    }]);
    provider.refreshPayments(ref);
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
            PaymentEditModal(
              base: editing,
              onFinish: (payment) {
                Navigator.pop(context, payment);
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

  Future<void> onRefreshButtonPressed() => refresh();

  @override
  Widget build(BuildContext context) {
    final payment = ref.watch(provider.payments).firstWhere((element) => element.pid == ref.watch(local_provider.selectedPayment));
    final transactions = ref.watch(_filteredTransactions);
    final total = transactions.fold(Decimal.zero, (previousValue, element) {
      if (payment.currency == element.currency) {
        return previousValue + element.amount;
      } else if (payment.currency == element.altCurrency) {
        if (element.altAmount == null) {
          Log.w(_tag, "Transaction ${element.pid} - Null AltAmount");
        }
        return previousValue + (element.altAmount ?? Decimal.zero);
      }
      return previousValue;
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(payment.descriptions),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showPaymentEditingModal(context, payment),
          ),
        ],
      ),
      body: WalletItemDetailsFragment<Payment>(
        item: payment,
        content: total,
        transactions: transactions,
        month: month,
        isReverse: isReverse,
        onMonthChanged: onMonthChanged,
        onSortButtonPressed: onSortButtonPressed,
        onRefreshButtonPressed: onRefreshButtonPressed,
        onTransactionEdit: (item) => refresh(),
      ),
      floatingActionButton: TransactionAddButton(
        payment: payment,
        onFinish: (item) => refresh(),
      ),
    );
  }

}