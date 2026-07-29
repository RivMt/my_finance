import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/modal/payment_edit_modal.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/fragment/wallet_item_details_fragment.dart';

const _tag = "PaymentDetailsPage";

final _uuid = StateNotifierProvider<ValueStateNotifier<String>, String>((ref) {
  return ValueStateNotifier(Payment.unknown.uuid);
});

final _payment = Provider<Payment>((ref) {
  final payments = ref.watch(provider.payments);
  final uuid = ref.watch(_uuid);
  return payments.firstWhere((element) => element.uuid == uuid, orElse: () => Payment.unknown);
});

final _filteredTransactions = Provider<List<Transaction>>((ref) {
  final date = ref.watch(_dateFilter);
  final begin = DateTime(date.year, date.month, 1);
  final end = DateTime(date.year, date.month + 1, 1);
  final sort = ref.watch(_sortFilter);
  final uuid = ref.watch(_uuid);
  List<Transaction> list = ref.watch(provider.transactions);
  list = list.where((item) {
    return !item.deleted
        && item.paidDate.compareTo(begin) >= 0
        && item.paidDate.compareTo(end) == -1
        && item.paymentId == uuid;
  }).toList();
  if (sort) {
    list = list.reversed.toList();
  }
  return list;
});

final _dateFilter = StateNotifierProvider<ValueStateNotifier<DateTime>, DateTime>((ref) {
  return ValueStateNotifier<DateTime>(DateTime(DateTime.now().year, DateTime.now().month, 1));
});

final _sortFilter = StateNotifierProvider<ValueStateNotifier<bool>, bool>((ref) {
  return ValueStateNotifier<bool>(false);
});

/// Displays a payment total and its monthly transactions.
class PaymentDetailsPage extends ConsumerStatefulWidget {

  const PaymentDetailsPage({
    super.key,
    required this.uuid,
  });

  /// UUID of the payment to display.
  final String uuid;

  @override
  ConsumerState createState() => _PaymentDetailsPageState();

}

class _PaymentDetailsPageState extends ConsumerState<PaymentDetailsPage> {

  /// Whether transactions are shown in reverse order.
  bool get isReverse => ref.watch(_sortFilter);

  /// Month currently displayed.
  DateTime get month => ref.watch(_dateFilter);

  set month(DateTime value) {
    ref.read(_dateFilter.notifier).set(value);
  }

  /// Appends transactions for the current payment.
  Future<void> fetchTransactions() async {
    final uuid = ref.watch(_uuid);
    provider.appendTransactions(ref, {
      ModelKeys.keyPaymentId: uuid,
    });
  }

  /// Changes the month and requests payment transactions.
  void onMonthChanged(DateTime value) {
    month = value;
    fetchTransactions();
  }

  /// Shows the payment editing modal and refreshes transactions afterward.
  void showPaymentEditingModal(BuildContext context, [Payment? payment]) async {
    showModalBottomSheet<Payment>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) {
        return Wrap(
          children: [
            PaymentEditModal(payment),
          ],
        );
      },
    ).then((item) {
      fetchTransactions();
    });
  }

  /// Toggles transaction ordering.
  void onSortButtonPressed() {
    ref.read(_sortFilter.notifier).set(!isReverse);
  }

  /// Refreshes payment transactions.
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
    final payment = ref.watch(_payment);
    final transactions = ref.watch(_filteredTransactions);
    final total = transactions.fold(Decimal.zero, (previousValue, element) {
      if (payment.currencyId == element.currencyId) {
        return previousValue + element.amount;
      } else if (payment.currencyId == element.altCurrencyId) {
        if (element.altAmount == null) {
          Log.w(_tag, "Transaction ${element.uuid} - Null AltAmount");
        }
        return previousValue + (element.altAmount ?? Decimal.zero);
      }
      return previousValue;
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(payment.name),
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
      ),
      floatingActionButton: TransactionAddButton(
        payment: payment,
      ),
    );
  }

}
