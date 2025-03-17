import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/dialog/currency_select_dialog.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class AmountField extends ConsumerStatefulWidget {
  const AmountField({
    super.key,
    this.currencyId = Currency.unknownUuid,
    this.label = "",
    required this.amount,
    required this.onCurrencyChanged,
    required this.onAmountChanged,
  });

  final String currencyId;

  final Decimal amount;

  final String label;

  final Function(Currency) onCurrencyChanged;

  final Function(Decimal) onAmountChanged;

  @override
  ConsumerState createState() => _AmountFieldState();

}

class _AmountFieldState extends ConsumerState<AmountField> {

  /// [TextEditingController] for budget amount
  final controller = TextEditingController();

  /// Currency
  Currency get currency => provider.getCurrency(ref, widget.currencyId);

  /// [RegExp] for verify amount
  RegExp get regex => WalletItem.getAmountRegex(currency);

  /// Show currency selection dialog
  void onCurrencyPressed(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => const CurrencySelectDialog(),
    );
    widget.onCurrencyChanged(result);
  }

  /// Triggers on [TextField] value changed
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
        prefix: IconButton(
          icon: CurrencyIcon(currency),
          onPressed: () => onCurrencyPressed(context),
        ),
        errorText: regex.hasMatch(controller.text)
            ? null
            : LocaleKeys.msgInvalidInput,
      ),
      inputFormatters: [
        FilteringTextInputFormatter(RegExp(r"[\d.]"), allow: true),
      ],
      onChanged: onTextFieldChanged,
    );
  }
}