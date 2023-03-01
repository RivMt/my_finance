import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/priority_edit_fragment.dart';

final _total = StateNotifierProvider<CalculateValueState, Decimal>((ref) {
  return CalculateValueState<Transaction>(
    ref,
    conditions: [{
      ModelKeys.keyPid: -1,
    }],
    type: CalculationType.sum,
    attribute: ModelKeys.keyAmount,
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
  ConsumerState createState() => _PaymentDetailsFragmentState();
}

class _PaymentDetailsFragmentState extends ConsumerState<PaymentDetailsFragment> {

  /// Request total amount
  ///
  /// This method changes [_total]'s condition.
  void request() {
    // Payment
    ref.read(_payment.notifier).request({
      ModelKeys.keyPid: widget.payment.pid,
    });
    // Default condition
    List<Map<String, dynamic>> conditions = [{
      ModelKeys.keyPaymentID: widget.payment.pid,
      ModelKeys.keyType: TransactionType.expense.code,
      ModelKeys.keyDeleted: false,
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

  /// Triggers on [PriorityEditFragment] pressed
  void onPressed(Payment payment, int priority) async {
    payment.priority = priority;
    final result = await ApiClient().update<Payment>([payment.map]);
    if (result.result == ApiResultCode.success) {
      setState(() {});
    }
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              WalletItemIcon(
                icon: payment.icon.icon,
                foreground: payment.foreground,
                background: payment.background,
              ),
              const SizedBox(width: 8,),
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
            ],
          ),
        ),
        PriorityEditFragment<Payment>(
          data: payment,
          onPressed: (priority) => onPressed(payment, priority),
        ),
      ],
    );
  }
}