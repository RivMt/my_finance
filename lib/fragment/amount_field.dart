import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/dialog/currency_select_dialog.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

/// Edits a currency-specific [Decimal] amount.
class AmountField extends ConsumerStatefulWidget {
  const AmountField({
    super.key,
    this.currency,
    this.label = "",
    required this.amount,
    required this.onCurrencyChanged,
    required this.onAmountChanged,
  });

  /// Selected currency, or the configured default currency.
  final Currency? currency;

  /// Current amount.
  final Decimal amount;

  /// Input label.
  final String label;

  /// Called when the selected currency changes.
  final Function(Currency) onCurrencyChanged;

  /// Called when a valid amount is entered.
  final Function(Decimal) onAmountChanged;

  @override
  ConsumerState createState() => _AmountFieldState();

}

class _AmountFieldState extends ConsumerState<AmountField> {

  /// Controls the amount input.
  final controller = TextEditingController();

  /// Resolved selected or default currency.
  Currency get currency => provider.getCurrency(ref, widget.currency?.uuid);

  /// Currency-aware amount validation pattern from [WalletItem].
  RegExp get regex => WalletItem.getAmountRegex(currency);

  /// Shows the currency selection dialog.
  void onCurrencyPressed(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => const CurrencySelectDialog(),
    );
    widget.onCurrencyChanged(result);
  }

  /// Validates and reports an amount input change.
  void onTextFieldChanged(String string) {
    Decimal value = Decimal.zero;
    if (regex.hasMatch(string)) {
      value = string == "" ? Decimal.zero : Decimal.parse(string);
    } else {
      controller.text = widget.amount.toString();
    }
    widget.onAmountChanged(value);
  }

  @override
  void initState() {
    super.initState();
    controller.text = widget.amount.toString();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: currency.decimalPoint > 0,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: IconButton(
          onPressed: () => onCurrencyPressed(context),
          icon: CurrencyIcon(currency),
        ),
        errorText: regex.hasMatch(controller.text)
            ? null
            : LocaleKeys.msgInvalidInput.tr(),
      ),
      inputFormatters: [
        FilteringTextInputFormatter(RegExp(r"[\d.]"), allow: true),
      ],
      onChanged: onTextFieldChanged,
    );
  }
}
