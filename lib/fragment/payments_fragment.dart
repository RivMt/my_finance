import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/modal/payment_edit_modal.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

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

  final List<Payment> payments;

  final Payment? selected;

  final String subtitle;

  final bool hideCreateButton;

  final Function(Payment)? onItemTap;

  final List<Map<String, dynamic>>? paymentsConditions;

  final List<Map<String, dynamic>>? amountConditions;

  /// Show payment editing modal
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

  /// Triggers on payment add button pressed
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
          // Tailing button
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