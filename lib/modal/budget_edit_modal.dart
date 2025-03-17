import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/amount_field.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class BudgetEditModal extends ConsumerStatefulWidget {
  const BudgetEditModal({
    super.key,
    this.currencyId = Currency.unknownUuid,
    this.value,
    required this.onConfirmButtonPressed,
    required this.onNegativeButtonPressed,
  });

  final Decimal? value;

  final String currencyId;

  final Function() onNegativeButtonPressed;

  final Function(String, Decimal) onConfirmButtonPressed;

  @override
  ConsumerState createState() => _BudgetEditModalState();
}

class _BudgetEditModalState extends ConsumerState<BudgetEditModal> {

  /// Is this fragment editing [Preference]
  ///
  /// This returns `true` when [widget.value] is not `null`
  bool get isEdit => widget.value != null;

  /// [Decimal] which is now editing
  Decimal amount = Decimal.zero;

  /// Selected [Currency]
  String currencyId = Currency.unknownUuid;

  /// Triggers on currency changed
  void onCurrencyChanged(Currency currency) {
    setState(() {
      currencyId = currency.uuid;
    });
  }

  /// Triggers on budget text field changed
  void onBudgetChanged(Decimal value) {
    setState(() {
      amount = value;
    });
  }

  /// Triggers on positive button pressed
  Future<bool> onPos() async {
    widget.onConfirmButtonPressed(currencyId, amount);
    return true;
  }

  /// Triggers on negative button pressed
  Future<bool> onNeg() async {
    widget.onNegativeButtonPressed();
    return true;
  }

  @override
  void initState() {
    super.initState();
    amount = widget.value ?? Decimal.zero;
    currencyId = widget.currencyId;
  }

  @override
  Widget build(BuildContext context) {
    return Modal(
      ready: true,
      title: LocaleKeys.object_action.tr(namedArgs: {
        "object": LocaleKeys.budget.plural(1),
        "action": isEdit ? LocaleKeys.edit.tr() : LocaleKeys.add.tr(),
      }),
      positiveButtonTitle: LocaleKeys.confirm.tr(),
      negativeButtonTitle: isEdit ? LocaleKeys.delete.tr() : LocaleKeys.cancel.tr(),
      onPositiveButtonPressed: onPos,
      onNegativeButtonPressed: onNeg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic information
          Text(
            LocaleKeys.budget.plural(1),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8,),
          // Limitation
          AmountField(
            label: LocaleKeys.limitation.tr(),
            currencyId: currencyId,
            amount: amount,
            onCurrencyChanged: onCurrencyChanged,
            onAmountChanged: onBudgetChanged,
          ),
        ],
      ),
    );
  }
}