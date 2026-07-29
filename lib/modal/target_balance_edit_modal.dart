import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/amount_field.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

/// Creates or edits a target balance preference.
class TargetBalanceEditModal extends ConsumerStatefulWidget {
  const TargetBalanceEditModal({
    super.key,
    this.date,
    this.currency,
    this.amount,
    required this.onConfirmButtonPressed,
    required this.onNegativeButtonPressed,
  });

  /// Existing target date, if any.
  final DateTime? date;

  /// Existing target currency, if any.
  final Currency? currency;

  /// Existing target amount, if any.
  final Decimal? amount;

  /// Called when the modal is cancelled or an existing target is removed.
  final Function() onNegativeButtonPressed;

  /// Called with the confirmed target balance.
  final Function(DateTime, Currency, Decimal) onConfirmButtonPressed;

  @override
  ConsumerState createState() => _TargetBalanceEditModalState();
}

class _TargetBalanceEditModalState extends ConsumerState<TargetBalanceEditModal> {

  /// Whether an existing target balance is being edited.
  bool get isEdit => widget.amount != null;

  /// Target date being edited.
  late DateTime date;

  /// Currency being edited.
  Currency currency = Currency.unknown;

  /// Target amount being edited.
  Decimal amount = Decimal.zero;

  /// Updates the target date.
  void onDateChanged(DateTime date) {
    setState(() {
      this.date = date;
    });
  }

  /// Updates the target currency.
  void onCurrencyChanged(Currency currency) {
    setState(() {
      this.currency = currency;
    });
  }

  /// Updates the target amount.
  void onAmountChanged(Decimal value) {
    setState(() {
      amount = value;
    });
  }

  /// Confirms the target balance.
  Future<bool> onPos() async {
    widget.onConfirmButtonPressed(date, currency, amount);
    return true;
  }

  /// Cancels creation or removes the existing target.
  Future<bool> onNeg() async {
    widget.onNegativeButtonPressed();
    return true;
  }

  @override
  void initState() {
    super.initState();
    date = widget.date ?? DateTime(
      DateTime.now().year,
      DateTime.now().month+1,
      0,
    );
    currency = widget.currency ?? Currency.unknown;
    amount = widget.amount ?? Decimal.zero;
  }

  @override
  Widget build(BuildContext context) {
    return Modal(
      ready: true,
      title: LocaleKeys.object_action.tr(namedArgs: {
        "object": LocaleKeys.targetBalance.plural(1),
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
          // Target date.
          Text(
            LocaleKeys.date.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                LocaleKeys.date.tr(),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              DateButton(
                date: date,
                onChanged: onDateChanged,
              ),
            ],
          ),
          // Target details.
          Text(
            LocaleKeys.targetBalance.plural(1),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8,),
          // Target amount and currency.
          AmountField(
            label: LocaleKeys.amount.tr(),
            currency: currency,
            amount: amount,
            onCurrencyChanged: onCurrencyChanged,
            onAmountChanged: onAmountChanged,
          ),
        ],
      ),
    );
  }
}
