import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/modal/payment_edit_modal.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

/// Groups payments by [PaymentSymbol] and provides editing actions.
class PaymentsFragment extends ConsumerWidget {
  const PaymentsFragment({
    super.key,
    required this.payments,
    this.subtitle = "",
    this.selected,
    this.hideCreateButton = false,
    this.onItemTap,
    this.paymentsConditions,
    this.amountConditions,
  });

  /// Payments to display.
  final List<Payment> payments;

  /// Payment highlighted as selected.
  final Payment? selected;

  /// Optional subtitle for payment content.
  final String subtitle;

  /// Whether to hide the payment creation button.
  final bool hideCreateButton;

  /// Called when a payment is tapped.
  final Function(Payment)? onItemTap;

  /// Conditions used to query payments.
  final List<Map<String, dynamic>>? paymentsConditions;

  /// Conditions used to calculate payment amounts.
  final List<Map<String, dynamic>>? amountConditions;

  /// Shows the payment creation or editing modal.
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
    );
  }

  /// Opens the payment creation modal.
  void onPaymentAddButtonPressed(BuildContext context) {
    showPaymentEditingModal(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: MasonryGridView.count(
        itemCount: PaymentSymbol.values.length + 1,
        crossAxisCount: ScreenPlanner(context).panelNumber,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        itemBuilder: (context, index) {
          // Payment creation button.
          if (index == PaymentSymbol.values.length) {
            return Visibility(
              visible: !hideCreateButton,
              child: ListTailButton(
                icon: Icons.add,
                title: LocaleKeys.add.tr(),
                onTap: () => onPaymentAddButtonPressed(context),
              ),
            );
          }
          final icon = PaymentSymbol.values[index];
          final sublist = payments.where((element) => (element.icon == icon)).toList(growable: false);
          // Omit empty symbol groups.
          if (sublist.isEmpty) {
            return const SizedBox();
          }
          // Symbol group.
          return GroupCard(
            title: icon.key.tr(),
            count: sublist.length,
            build: (context, index) {
              final payment = sublist[index];
              return PaymentCard(
                data: payment,
                selected: selected == payment,
                ignoreDeleted: true,
                onTap: () {
                  if (onItemTap == null) {
                    return;
                  }
                  onItemTap!(payment);
                },
                onLongPress: () {
                  showPaymentEditingModal(context, payment);
                },
              );
            },
          );
        },
      ),
    );
  }
}
