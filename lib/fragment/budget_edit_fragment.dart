import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/dialog/currency_select_dialog.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class BudgetEditFragment extends ConsumerStatefulWidget {
  const BudgetEditFragment({
    super.key,
    this.value,
    this.currency = Currency.unknown,
    required this.onConfirmButtonPressed,
    required this.onNegativeButtonPressed,
  });

  final Decimal? value;

  final Currency currency;

  final Function() onNegativeButtonPressed;

  final Function(Currency, Decimal) onConfirmButtonPressed;

  @override
  ConsumerState createState() => _BudgetEditFragmentState();
}

class _BudgetEditFragmentState extends ConsumerState<BudgetEditFragment> {

  /// Is this fragment editing [Preference]
  ///
  /// This returns `true` when [widget.value] is not `null`
  bool get isEdit => widget.value != null;

  /// [Decimal] which is now editing
  Decimal amount = Decimal.zero;

  /// Selected [Currency]
  Currency currency = Currency.unknown;

  /// Value of sent [amount] and waiting for response
  bool _progressing = false;

  /// Value of sent [amount] and waiting for response
  ///
  /// This is wrapper of [_progressing]. When setting this, [setState] called
  /// automatically
  bool get progressing => _progressing;

  set progressing(bool value) {
    _progressing = value;
    setState(() {});
  }

  /// [TextEditingController] for budget amount
  final budgetController = TextEditingController();

  /// Show currency selection dialog
  void onCurrencyChanged(BuildContext context) async {
    final result =  await showDialog(
      context: context,
      builder: (context) => const CurrencySelectDialog(),
    );
    setState(() {
      currency = result;
    });
  }

  /// Triggers on budget text field changed
  void onBudgetChanged(String value) {
    if (FinanceModel.getRegex(Account.maxIntegerPartDigits, widget.currency.decimalDigits).hasMatch(value)) {
      amount = value == "" ? Decimal.zero : Decimal.parse(value);
    } else {
      budgetController.text = amount.toString();
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    amount = widget.value ?? Decimal.zero;
    currency = widget.currency;
    budgetController.text = amount.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ModalHeader(
              disabled: progressing,
              headerTitle: LocaleKeys.object_action.tr(namedArgs: {
                "object": LocaleKeys.budget.plural(1),
                "action": isEdit ? LocaleKeys.edit.tr() : LocaleKeys.add.tr(),
              }),
              positiveButtonTitle: LocaleKeys.confirm.tr(),
              negativeButtonTitle: isEdit ? LocaleKeys.delete.tr() : LocaleKeys.cancel.tr(),
              onPositiveButtonPressed: progressing ? null : () => widget.onConfirmButtonPressed(currency, amount),
              onNegativeButtonPressed: progressing ? null : widget.onNegativeButtonPressed,
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(8),
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
                  TextField(
                    controller: budgetController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.limitation.tr(),
                      prefix: IconButton(
                        icon: Icon(currency.icon),
                        onPressed: () => onCurrencyChanged(context),
                      ),
                    ),
                    onChanged: onBudgetChanged,
                  ),
                ],
              ),
            ),
            // Progress
            Visibility(
              visible: progressing,
              child: const LinearProgressIndicator(value: null,),
            ),
          ],
        ),
      ),
    );
  }
}