import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/fragment/payment_details_fragment.dart';
import 'package:my_finance/fragment/payments_fragment.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/page/payment_details_page.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({
    super.key,
    this.condition,
  });

  final Map<String, dynamic>? condition;

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

  /// Value of right side panel is visible or not
  bool get transactionsVisible {
    final int number = InterfaceConstructor.panelNumber(context);
    return number == 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width / InterfaceConstructor.panelNumber(context);
    final payment = selected ?? Payment.unknown;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.payment.plural(2)),
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
                  onItemTap: (item) => onPaymentSelected,
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
                  // 0: No account
                  MessageBox(
                    icon: Icons.question_mark_outlined,
                    message: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
                      "object": LocaleKeys.payment.plural(1),
                    }),
                  ),
                  // 1: Account details and transactions
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: PaymentDetailsFragment(
                          payment: payment,
                          condition: widget.condition,
                        ),
                      ),
                      Expanded(
                        child: TransactionsFragment(
                          condition: {
                            Transaction.keyPaymentID: payment.pid,
                          },
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
    );
  }
}