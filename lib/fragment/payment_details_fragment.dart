import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';

final _total = StateNotifierProvider<CalculateValueState, Decimal>((ref) {
  return CalculateValueState<Transaction>(
    ref,
    conditions: [{}],
    type: CalculationType.sum,
    attribute: Transaction.keyAmount,
  );
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
    // Default condition
    List<Map<String, dynamic>> conditions = [{
      Transaction.keyPaymentID: widget.payment.pid,
      Transaction.keyType: TransactionType.expense.code,
      FinanceModel.keyDeleted: false,
    }];
    // Merge custom condition
    if (widget.conditions != null) {
      for(int i=0; i < min(conditions.length, widget.conditions!.length); i++) {
        conditions[i] = {
          ...conditions[i],
          ...widget.conditions![i],
        };
      }
    }
    // Refresh condition
    ref.read(_total.notifier).conditions = conditions;
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
                widget.payment.serialNumber,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                widget.payment.currency.format(amount),
                style: Theme.of(context).textTheme.displayLarge,
              ),
              Text(
                widget.payment.descriptions,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        WalletItemIcon(
          icon: widget.payment.icon.icon,
          foreground: widget.payment.foreground,
          background: widget.payment.background,
        ),
      ],
    );
  }
}