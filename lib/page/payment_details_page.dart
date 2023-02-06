import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/fragment/payment_details_fragment.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

final _payments = StateNotifierProvider<FinanceModelState<Payment>, List<Payment>>((ref) {
  return FinanceModelState<Payment>(ref);
});

class PaymentDetailsPage extends ConsumerStatefulWidget {
  const PaymentDetailsPage({
    super.key,
    required this.pid,
  });
  
  final int pid;

  @override
  _PaymentDetailsPageState createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends ConsumerState<PaymentDetailsPage> {
  
  /// Request payment using [widget.pid]
  void request() {
    ref.read(_payments.notifier).request([{
      FinanceModel.keyPid: widget.pid,
    }]);
  }

  @override
  void initState() {
    super.initState();
    request();
  }

  @override
  void didUpdateWidget(PaymentDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    late Payment? payment;
    if (ref.watch(_payments).isNotEmpty) {
      payment = ref.watch(_payments)[0];
    } else {
      payment = null;
    }
    return Scaffold(
      body: IndexedStack(
        index: payment == null ? 0 : 1,
        children: [
          // 0: No payment
          MessageBox(
            icon: Icons.question_mark_outlined,
            message: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
              "object": LocaleKeys.payment.plural(1),
            }),
          ),
          // 1: Payment details
          CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(payment!.descriptions),
                floating: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                sliver: SliverToBoxAdapter(
                  child: PaymentDetailsFragment(
                    payment: payment,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: TransactionsFragment(
                  useSliver: true,
                  condition: {
                    Transaction.keyPaymentID: payment.pid,
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}