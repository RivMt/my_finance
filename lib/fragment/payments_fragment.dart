import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/fragment/payment_edit_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class PaymentsFragment extends ConsumerStatefulWidget {
  const PaymentsFragment({
    super.key,
    required this.payments,
    this.subtitle = "",
    this.selected,
    this.currency = Currency.unknown,
    this.hideCreateButton = false,
    this.onItemTap,
    this.onEditFinish,
    this.paymentsConditions,
    this.amountConditions,
  });

  final List<Payment> payments;

  final Payment? selected;

  final Currency currency;

  final String subtitle;

  final bool hideCreateButton;

  final Function(Payment)? onItemTap;

  final Function(Payment)? onEditFinish;

  final List<Map<String, dynamic>>? paymentsConditions;

  final List<Map<String, dynamic>>? amountConditions;

  @override
  ConsumerState createState() => _PaymentsFragmentState();
}

class _PaymentsFragmentState extends ConsumerState<PaymentsFragment> {

  /// Currently selected [Currency]
  ///
  /// **DO NOT** use this directly. Use [currency] than.
  /// This save user selected currency. By the default, it is `null` and
  /// user selects a currency, the value will be saved here.
  Currency? _currency;

  /// Currently selected [Currency]
  ///
  /// If [_currency] is `null`, return [widget.currency].
  /// This i
  Currency get currency => _currency ?? widget.currency;

  set currency(Currency value) => _currency = value;

  /// Show payment editing modal
  void showPaymentEditingModal(BuildContext context, [Payment? payment]) async {
    Payment? editing = payment;
    showModalBottomSheet<Payment>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) {
        return Wrap(
          children: [
            PaymentEditFragment(
              base: editing,
              onFinish: (payment) {
                Navigator.pop(context, payment);
              },
            ),
          ],
        );
      },
    ).then((payment) {
      provider.refreshPayments(ref);
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: PaymentSymbol.values.length,
            itemBuilder: (context, index) {
              final icon = PaymentSymbol.values[index];
              final sublist = widget.payments.where((element) => (element.icon == icon)).toList(growable: false);
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
          Visibility(
            visible: !widget.hideCreateButton,
            child: ListTailButton(
              icon: Icons.add,
              title: LocaleKeys.add.tr(),
              onTap: () => onPaymentAddButtonPressed(context),
            ),
          ),
        ],
      ),
    );
  }
}