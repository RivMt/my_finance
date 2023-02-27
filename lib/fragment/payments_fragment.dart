import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/payment_edit_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

final _payments = StateNotifierProvider<ModelsState<Payment>, List<Payment>>((ref) {
  return ModelsState<Payment>(ref);
});

final _amount = StateNotifierProvider<CalculateValueState<Transaction>, Decimal>((ref) {
  return CalculateValueState<Transaction>(ref,
    conditions: [],
    type: CalculationType.sum,
    attribute: Transaction.keyAmount,
  );
});

class PaymentsFragment extends ConsumerStatefulWidget {
  const PaymentsFragment({
    super.key,
    this.subtitle = "",
    this.selected,
    this.currency = Currency.unknown,
    this.hideCreateButton = false,
    this.onItemTap,
    this.onEditFinish,
    this.paymentsConditions,
    this.amountConditions,
  });

  final Payment? selected;

  final Currency currency;

  final String subtitle;

  final bool hideCreateButton;

  final Function(Payment)? onItemTap;

  final Function(Payment)? onEditFinish;

  final List<Map<String, dynamic>>? paymentsConditions;

  final List<Map<String, dynamic>>? amountConditions;

  @override
  _PaymentsFragmentState createState() => _PaymentsFragmentState();
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

  /// Request all payments ordered by icon
  void request() {
    // Payments
    ref.read(_payments.notifier).request(
      widget.paymentsConditions ?? [{
        FinanceModel.keyDeleted: false,
        Payment.keyCurrency: currency.value,
        WalletItem.keyPriority: {
          "min": 0,
        },
      }],
      ApiClient.buildOptions(
        sorts: [
          const Sort(Payment.keyIcon, SortType.asc),
          const Sort(FinanceModel.keyLastUsed, SortType.desc),
        ],
      ),
    );
    // Amount
    if (widget.amountConditions != null) {
      final conditions = widget.amountConditions!;
      for(Map map in conditions) {
        map[Payment.keyCurrency] = currency.value;
      }
      ref.read(_amount.notifier).conditions = conditions;
      ref.read(_amount.notifier).request();
    }
  }

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
      request();
      if (widget.onEditFinish != null && payment != null) {
        widget.onEditFinish!(payment);
      }
    });
  }

  /// Triggers on currency menu button pressed
  void onCurrencyButtonPressed(Currency currency) {
    this.currency = currency;
    request();
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
    final amount = ref.watch(_amount);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible: widget.amountConditions != null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Visibility(
                        visible: widget.subtitle.isNotEmpty,
                        child: Text(
                          widget.subtitle,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Text(
                        currency.format(amount),
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ],
                  ),
                  PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    onSelected: onCurrencyButtonPressed,
                    itemBuilder: (BuildContext context) => Currency.validValues.map((currency) {
                      return PopupMenuItem(
                        value: currency,
                        child: ListTile(
                          leading: Icon(currency.icon),
                          title: Text(currency.key.tr()),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
          // List
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: PaymentSymbol.values.length,
            itemBuilder: (context, index) {
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