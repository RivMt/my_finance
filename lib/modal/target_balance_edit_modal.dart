import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/amount_field.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class TargetBalanceEditModal extends ConsumerStatefulWidget {
  const TargetBalanceEditModal({
    super.key,
    this.date,
    this.currency,
    this.amount,
    required this.onConfirmButtonPressed,
    required this.onNegativeButtonPressed,
  });

  final DateTime? date;

  final Currency? currency;

  final Decimal? amount;

  final Function() onNegativeButtonPressed;

  final Function(DateTime, Currency, Decimal) onConfirmButtonPressed;

  @override
  ConsumerState createState() => _TargetBalanceEditModalState();
}

class _TargetBalanceEditModalState extends ConsumerState<TargetBalanceEditModal> {

  /// Is this fragment editing [Preference]
  ///
  /// This returns `true` when [widget.value] is not `null`
  bool get isEdit => widget.amount != null;

  /// Expired [DateTime] of target balance
  late DateTime date;

  /// UUID of selected [Currency]
  Currency currency = Currency.unknown;

  /// [Decimal] which is now editing
  Decimal amount = Decimal.zero;

  /// Triggers on date changed
  void onDateChanged(DateTime date) {
    setState(() {
      this.date = date;
    });
  }

  /// Triggers on currency changed
  void onCurrencyChanged(Currency currency) {
    setState(() {
      this.currency = currency;
    });
  }

  /// Triggers on budget text field changed
  void onAmountChanged(Decimal value) {
    setState(() {
      amount = value;
    });
  }

  /// Triggers on positive button pressed
  Future<bool> onPos() async {
    widget.onConfirmButtonPressed(date, currency, amount);
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
          // Date
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
          // Basic information
          Text(
            LocaleKeys.targetBalance.plural(1),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8,),
          // Limitation
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