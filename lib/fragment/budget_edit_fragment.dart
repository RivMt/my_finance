import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class BudgetEditFragment extends ConsumerStatefulWidget {
  const BudgetEditFragment({
    super.key,
    required this.onFinish,
    required this.currency,
    required this.onConfirmButtonPressed,
    required this.onNegativeButtonPressed,
    this.base,
  });

  final Decimal? base;

  final Currency currency;

  final Function(Decimal?) onFinish;

  final Function() onNegativeButtonPressed;

  final Function(Decimal) onConfirmButtonPressed;

  @override
  _BudgetEditFragmentState createState() => _BudgetEditFragmentState();
}

class _BudgetEditFragmentState extends ConsumerState<BudgetEditFragment> {

  /// Is this fragment editing [Preference]
  ///
  /// This returns `true` when [widget.base] is not `null`
  bool get isEdit => widget.base != null;

  /// [Decimal] which is now editing
  Decimal editing = Decimal.zero;

  /// Value of sent [editing] and waiting for response
  bool _progressing = false;

  /// Value of sent [editing] and waiting for response
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

  /// Triggers on budget text field changed
  void onBudgetChanged(String value) {
    if (FinanceModel.getRegex(Account.maxIntegerPartDigits, widget.currency.decimalDigits).hasMatch(value)) {
      editing = value == "" ? Decimal.zero : Decimal.parse(value);
    } else {
      budgetController.text = editing.toString();
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    editing = widget.base ?? Decimal.zero;
    budgetController.text = editing.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            onPositiveButtonPressed: progressing ? null : () => widget.onConfirmButtonPressed(editing),
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
                    prefixIcon: Icon(widget.currency.icon),
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
    );
  }
}