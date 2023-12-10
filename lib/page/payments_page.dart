import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/fragment/payment_details_fragment.dart';
import 'package:my_finance/fragment/payments_fragment.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

final _filteredPayments = Provider<List<Payment>>((ref) {
  final min = ref.watch(_minPriorityFilter);
  final max = ref.watch(_maxPriorityFilter);
  final sort = ref.watch(_sortFilter);
  final list = ref.watch(provider.payments);
  List<Payment> result = list
      .where((payment) => (payment.priority >= min && payment.priority <= max)).toList();
  if ( Payment.unknown.map.containsKey(sort)) {
    result.sort((a1, a2) =>
        (a1.map[sort] as Comparable).compareTo(a2.map[sort]));
  }
  return result;
});

final _minPriorityFilter = StateNotifierProvider<ModelState<int>, int>((ref) {
  return ModelState<int>(ref, 0);
});

final _maxPriorityFilter = StateNotifierProvider<ModelState<int>, int>((ref) {
  return ModelState<int>(ref, 1000);
});

final _sortFilter = StateNotifierProvider<ModelState<String>, String>((ref) {
  return ModelState<String>(ref, ModelKeys.keyPid);
});


class PaymentsPage extends ConsumerStatefulWidget {

  static const String route = "/payments";

  const PaymentsPage({
    super.key,
    this.init,
    this.paymentCondition,
    this.amountCondition,
    this.subtitle = "",
    this.currency = Currency.unknown,
  });

  final String subtitle;

  final List<Map<String, dynamic>>? paymentCondition;

  final List<Map<String, dynamic>>? amountCondition;

  final Currency currency;

  final Payment? init;

  @override

  ConsumerState createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {

  /// Selected [Payment]
  Payment? selected;

  /// Open page
  void openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  /// Check page can be pop
  bool checkPageCanPop(BuildContext context) {
    if (!ScreenPlanner(context).isSidePanelVisible) {
      return selected == null;
    }
    return true;
  }

  /// Triggers on back button pressed
  void onBackButtonPressed(BuildContext context) {
    if (checkPageCanPop(context)) {
      Navigator.pop(context);
    }
    selected = null;
    setState(() {});
    return;
  }

  /// Triggers on [Payment] selected
  ///
  /// If [transactionVisible] is `true`, show transactions on right side,
  /// otherwise, open [PaymentDetailsPage]
  void onPaymentSelected(Payment payment) {
    selected = payment;
    setState(() {});
  }

  /// Triggers on transaction created
  void onTransactionCreated(Transaction? transaction) {
    if (transaction != null) {
      setState(() {});
    }
  }

  /// Condition for [TransactionsFragment]
  List<Map<String, dynamic>> get transactionsCondition {
    final con = {
      ModelKeys.keyPaymentID: (selected == null) ? -1 : selected!.pid,
    };
    if (widget.amountCondition == null) {
      return [con];
    }
    final List<Map<String, dynamic>> result = List.from(widget.amountCondition!);
    for(int i=0; i < result.length; i++) {
      result[i] = {
        ...result[i],
        ...con,
      };
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    selected = widget.init;
  }

  @override
  Widget build(BuildContext context) {
    final width = ScreenPlanner(context).panelWidth;
    final payment = selected ?? Payment.unknown;
    final sideVisible = ScreenPlanner(context).isSidePanelVisible;
    return WillPopScope(
      onWillPop: () async {
        final value = checkPageCanPop(context);
        if (!value) {
          selected = null;
          setState(() {});
        }
        return value;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocaleKeys.payment.plural(2)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => onBackButtonPressed(context),
          ),
        ),
        body: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payments
              Visibility(
                visible: sideVisible || payment == Payment.unknown,
                child: SizedBox(
                  width: width,
                  child: PaymentsFragment(
                    payments: ref.watch(_filteredPayments),
                    subtitle: widget.subtitle,
                    selected: selected,
                    paymentsConditions: widget.paymentCondition,
                    amountConditions: widget.amountCondition,
                    currency: widget.currency,
                    onItemTap: onPaymentSelected,
                    onEditFinish: (item) => setState(() {
                      selected = item;
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: TransactionAddButton(
          payment: payment,
          onFinish: onTransactionCreated,
        ),
      ),
    );
  }
}