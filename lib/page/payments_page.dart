import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/payment_details_fragment.dart';
import 'package:my_finance/fragment/payments_fragment.dart';
import 'package:my_finance/fragment/transaction_add_button.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({
    super.key,
    this.init,
    this.condition,
    this.subtitle = "",
    this.currency = Currency.unknown,
  });

  final String subtitle;

  final List<Map<String, dynamic>>? condition;

  final Currency currency;

  final Payment? init;

  @override
  State createState() => _PaymentsPageState();
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
                    subtitle: widget.subtitle,
                    selected: selected,
                    amountConditions: widget.condition,
                    currency: widget.currency,
                    onItemTap: onPaymentSelected,
                    onEditFinish: (item) => setState(() {
                      selected = item;
                    }),
                  ),
                ),
              ),
              // Transactions
              Visibility(
                visible: sideVisible || payment != Payment.unknown,
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
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PaymentDetailsFragment(
                              payment: payment,
                              conditions: widget.condition,
                            ),
                            const SizedBox(height: 8,),
                            Expanded(
                              child: TransactionsFragment(
                                conditions: transactionsCondition,
                                options: ApiClient.buildOptions(
                                  sorts: [
                                    const Sort(ModelKeys.keyLastUsed, SortType.desc),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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