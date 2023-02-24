import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';

final _total = StateNotifierProvider<CalculateValueState, Decimal>((ref) {
  return CalculateValueState<Transaction>(
    ref,
    conditions: [{
      FinanceModel.keyPid: -1,
    }],
    type: CalculationType.sum,
    attribute: Transaction.keyAmount,
  );
});

final _payment = StateNotifierProvider<ModelState<Payment>, Payment>((ref) {
  return ModelState<Payment>(ref, Payment.unknown);
});

class PaymentDetailsFragment extends ConsumerStatefulWidget {
  const PaymentDetailsFragment({
    super.key,
    required this.payment,
    this.conditions,
  });

  final Payment payment;

  final List<Map<String, dynamic>>? conditions;

  @override
  _PaymentDetailsFragmentState createState() => _PaymentDetailsFragmentState();
}

class _PaymentDetailsFragmentState extends ConsumerState<PaymentDetailsFragment> {

  /// Request total amount
  ///
  /// This method changes [_total]'s condition.
  void request() {
    // Payment
    ref.read(_payment.notifier).request({
      FinanceModel.keyPid: widget.payment.pid,
    });
    // Default condition
    List<Map<String, dynamic>> conditions = [{
      Transaction.keyPaymentID: widget.payment.pid,
      Transaction.keyType: TransactionType.expense.code,
      FinanceModel.keyDeleted: false,
    }];
    // Merge custom condition
    if (widget.conditions != null) {
      for(int i=0; i < conditions.length; i++) {
        for(int j=0; j < widget.conditions!.length; j++) {
          conditions[i] = {
            ...conditions[i],
            ...widget.conditions![j],
          };
        }
      }
    }
    // Refresh condition
    ref.read(_total.notifier).conditions = conditions;
    ref.read(_total.notifier).request();
  }

  @override
  void initState() {
    super.initState();
    request();
  }

  @override
  void didUpdateWidget(PaymentDetailsFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    final amount = ref.watch(_total);
    final payment = ref.watch(_payment);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.serialNumber,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                payment.currency.format(amount),
                style: Theme.of(context).textTheme.displayLarge,
              ),
              Text(
                payment.descriptions,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        WalletItemIcon(
          icon: payment.icon.icon,
          foreground: payment.foreground,
          background: payment.background,
        ),
      ],
    );
  }
}