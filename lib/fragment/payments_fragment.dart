import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/fragment/payment_edit_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

final _payments = StateNotifierProvider<FinanceModelState<Payment>, List<Payment>>((ref) {
  return FinanceModelState<Payment>(ref);
});

class PaymentsFragment extends ConsumerStatefulWidget {
  const PaymentsFragment({
    super.key,
    this.selected,
    this.onItemTap,
    this.onEditFinish,
  });

  final Payment? selected;

  final Function(Payment)? onItemTap;

  final Function(Payment)? onEditFinish;

  @override
  _PaymentsFragmentState createState() => _PaymentsFragmentState();
}

class _PaymentsFragmentState extends ConsumerState<PaymentsFragment> {

  /// Request all payments ordered by icon
  void request() {
    ref.read(_payments.notifier).request(
      [{
        FinanceModel.keyDeleted: false,
      }],
      ApiClient().buildOptions(
        sortOrderType: SortOrderType.asc,
        sortOrderAttribute: Payment.keyIcon,
      ),
    );
  }

  /// Show payment editing modal
  void showPaymentEditingModal(BuildContext context, [Payment? payment]) async {
    Payment? editing = payment;
    showModalBottomSheet<Payment>(
        context: context,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width / InterfaceConstructor.panelNumber(context),
        ),
        builder: (context) {
          return PaymentEditFragment(
            base: editing,
            onFinish: (payment) {
              Navigator.pop(context, payment);
            },
          );
        }
    ).then((payment) {
      request();
      if (widget.onEditFinish != null && payment != null) {
        widget.onEditFinish!(payment);
      }
    });
  }

  /// Triggers on payment add button pressed
  void onPaymentAddButtonPressed(BuildContext context) {
    showPaymentEditingModal(context);
  }

  @override
  void initState() {
    super.initState();
    request();
  }

  @override
  void didUpdateWidget(PaymentsFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(_payments);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List
          ListView.builder(
            shrinkWrap: true,
            itemCount: PaymentIcon.values.length,
            itemBuilder: (context, index) {
              final icon = PaymentIcon.values[index];
              final sublist = payments.where((element) => (element.icon == icon)).toList(growable: false);
              // Hide when sublist is empty
              if (sublist.isEmpty) {
                return const SizedBox();
              }
              // Group
              return GroupCard(
                title: icon.key.tr(),
                count: sublist.length,
                build: (context, index) {
                  final payment = sublist[index];
                  return PaymentCard(
                    data: payment,
                    selected: widget.selected == payment,
                    onTap: () {
                      if (widget.onItemTap == null) {
                        return;
                      }
                      widget.onItemTap!(payment);
                    },
                    onLongPress: () {
                      showPaymentEditingModal(context, payment);
                    },
                  );
                },
              );
            },
          ),
          // Add
          ListTailButton(
            icon: Icons.add,
            title: LocaleKeys.add.tr(),
            onTap: () => onPaymentAddButtonPressed(context),
          ),
        ],
      ),
    );
  }
}