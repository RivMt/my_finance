import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/payment_details_fragment.dart';
import 'package:my_finance/fragment/payments_fragment.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/page/payment_details_page.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({
    super.key,
    this.condition,
    this.title,
  });

  final List<Map<String, dynamic>>? condition;

  final String? title;

  @override
  _PaymentsPageState createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {

  /// Selected [Payment]
  Payment? selected;

  /// Open page
  void openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  /// Triggers on [Payment] selected
  ///
  /// If [transactionVisible] is `true`, show transactions on right side,
  /// otherwise, open [PaymentDetailsPage]
  void onPaymentSelected(Payment payment) {
    if (transactionsVisible) {
      selected = payment;
      setState(() {});
    } else {
      openPage(PaymentDetailsPage(pid: payment.pid));
    }
  }

  /// Triggers on transaction created
  void onTransactionCreated(Transaction? transaction) {
    if (transaction != null) {
      setState(() {});
    }
  }

  /// Value of right side panel is visible or not
  bool get transactionsVisible {
    final int number = InterfaceConstructor.panelNumber(context);
    return number == 2;
  }

  /// Condition for [TransactionsFragment]
  List<Map<String, dynamic>> get transactionsCondition {
    final con = {
      Transaction.keyPaymentID: (selected == null) ? -1 : selected!.pid,
    };
    if (widget.condition == null) {
      return [con];
    }
    final List<Map<String, dynamic>> result = List.from(widget.condition!);
    for(int i=0; i < result.length; i++) {
      result[i] = {
        ...result[i],
        ...con,
      };
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width / InterfaceConstructor.panelNumber(context);
    final payment = selected ?? Payment.unknown;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? LocaleKeys.payment.plural(2)),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Payments
          SizedBox(
            width: width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PaymentsFragment(
                  selected: selected,
                  conditions: widget.condition,
                  onItemTap: onPaymentSelected,
                  onEditFinish: (item) => setState(() {
                    selected = item;
                  }),
                ),
              ],
            ),
          ),
          // Transactions
          Visibility(
            visible: transactionsVisible,
            child: SizedBox(
              width: width,
              child: IndexedStack(
                index: payment == Payment.unknown ? 0 : 1,
                children: [
                  // 0: No payment
                  MessageBox(
                    icon: Icons.question_mark_outlined,
                    message: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
                      "object": LocaleKeys.payment.plural(1),
                    }),
                  ),
                  // 1: Payment details and transactions
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: PaymentDetailsFragment(
                          payment: payment,
                          conditions: widget.condition,
                        ),
                      ),
                      Expanded(
                        child: TransactionsFragment(
                          conditions: transactionsCondition,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Visibility(
        visible: InterfaceConstructor.isSidePanelVisible(context),
        child: TransactionAddButton(
          onFinish: onTransactionCreated,
        ),
      ),
    );
  }
}