import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/dialog/color_picker_dialog.dart';
import 'package:my_finance/dialog/currency_select_dialog.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

/// Creates, updates, or soft-deletes a [Payment].
class PaymentEditModal extends ConsumerStatefulWidget {
  const PaymentEditModal(this.base, {super.key});

  /// Payment to edit, or `null` when creating one.
  final Payment? base;

  @override
  ConsumerState createState() => _PaymentEditModalState();
}

class _PaymentEditModalState extends ConsumerState<PaymentEditModal> {

  final TextEditingController nameController = TextEditingController();

  final TextEditingController serialNumberController = TextEditingController();
  
  final TextEditingController limitationController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  /// Whether an existing payment is being edited.
  bool get isEdit => widget.base != null;

  /// Mutable payment being edited.
  Payment editing = Payment({});

  /// Whether the payment and limitation input are valid.
  bool get ready {
    return editing.isValid
        && (limitationController.text == editing.limitation.toString());
  }

  /// Builds a recent-color list from accounts and payments.
  List<Color> buildColorHistory() {
    List<Color> colors = [];
    // Account colors, newest first.
    final accounts = ref.watch(provider.accounts);
    accounts.sort((a, b) {
      return b.lastUsed.millisecondsSinceEpoch - a.lastUsed.millisecondsSinceEpoch;
    });
    for (Account account in accounts) {
      colors.add(account.foreground);
      colors.add(account.background);
    }
    // Payment colors, newest first.
    final payments = ref.watch(provider.payments);
    payments.sort((a, b) {
      return b.lastUsed.millisecondsSinceEpoch - a.lastUsed.millisecondsSinceEpoch;
    });
    for (Payment payment in payments) {
      colors.add(payment.foreground);
      colors.add(payment.background);
    }
    return colors.toSet().toList();
  }

  /// Shows the [PaymentSymbol] selection dialog.
  Future<PaymentSymbol?> showSymbolSelectDialog(BuildContext context) async {
    const list = PaymentSymbol.values;
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LocaleKeys.object_action.tr(namedArgs: {
            "object": LocaleKeys.icon.tr(),
            "action": LocaleKeys.select.tr(),
          })),
          content: SizedBox(
            width: ScreenPlanner(context).dialogWidth,
            height: MediaQuery.of(context).size.height * 0.7,
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return ListTile(
                  title: Text(item.key.tr()),
                  leading: Icon(item.icon),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Shows a color picker initialized with [color].
  Future<Color> showColorPicker(BuildContext context, Color color) async {
    final Color? result = await showDialog<Color>(
      context: context,
      builder: (context) {
        Color selected = color;
        return ColorPickerDialog(
          color: selected,
          onColorChanged: (value) => selected = value,
          palettes: buildColorHistory(),
        );
      }
    );
    return result ?? color;
  }

  /// Deletes the payment in edit mode or cancels creation.
  Future<bool> onNegativeButtonPressed() async {
    if (!isEdit) {
      return true;
    }
    return await provider.deletePayment(ref, editing);
  }

  /// Persists the payment being edited.
  Future<bool> onConfirmButtonPressed() async {
    if (isEdit) {
      return await provider.updatePayment(ref, editing);
    }
    return await provider.createPayment(ref, editing);
  }

  /// Updates the payment name.
  void onNameChanged(String name) {
    setState(() {
      editing.name = name;
    });
  }

  /// Updates the payment serial number.
  void onSerialNumberChanged(String serial) {
    setState(() {
      editing.serialNumber = serial;
    });
  }

  /// Updates the payment limitation when [value] is valid.
  void onLimitationChanged(String value) {
    final currency = provider.getCurrency(ref, editing.currencyId);
    setState(() {
      if (WalletItem.getAmountRegex(currency).hasMatch(value)) {
        if (value != "") {
          editing.limitation = Decimal.parse(value);
        }
      }
    });
  }

  /// Updates the payment description.
  void onDescriptionChanged(String desc) {
    setState(() {
      editing.descriptions = desc;
    });
  }

  /// Selects the payment symbol.
  void onPaymentIconButtonPressed() async {
    final icon = await showSymbolSelectDialog(context);
    if (icon != null) {
      setState(() {
        editing.icon = icon;
      });
    }
  }

  /// Selects the payment currency.
  void onCurrencyButtonPressed() async {
    final currency = await showDialog(
      context: context,
      builder: (context) => const CurrencySelectDialog(),
    );
    if (currency != null) {
      setState(() {
        editing.currencyId = currency.uuid;
      });
    }
  }

  /// Updates whether this payment handles credit transactions.
  void onCreditValueChanged(bool value) {
    setState(() {
      editing.isCredit = value;
    });
  }

  /// Updates the withdrawal day for each payment period.
  void onPayDateChanged(int? day) {
    if (day == null) {
      return;
    }
    setState(() {
      editing.payDate = day;
    });
  }

  /// Updates the beginning of the payment period.
  void onPayRangeBeginChanged(int? month, int? day) {
    if (month == null || day == null) {
      return;
    }
    setState(() {
      editing.payBegin = PaymentRangePoint(month, day);
    });
  }

  /// Updates the end of the payment period.
  void onPayRangeEndChanged(int? month, int? day) {
    if (month == null || day == null) {
      return;
    }
    setState(() {
      editing.payEnd = PaymentRangePoint(month, day);
    });
  }

  /// Selects the foreground color.
  void onForegroundPressed(BuildContext context) async {
    final value = await showColorPicker(context, editing.foreground);
    setState(() {
      editing.foreground = value;
    });
  }

  /// Selects the background color.
  void onBackgroundPressed(BuildContext context) async {
    final value = await showColorPicker(context, editing.background);
    setState(() {
      editing.background = value;
    });
  }

  @override
  void initState() {
    super.initState();
    editing = widget.base ?? Payment({});
    nameController.text = editing.name;
    serialNumberController.text = editing.serialNumber;
    limitationController.text = editing.limitation.toString();
    descriptionController.text = editing.descriptions;
  }

  @override
  Widget build(BuildContext context) {
    final currency = provider.getCurrency(ref, editing.currencyId);
    return Modal(
      title: LocaleKeys.object_action.tr(namedArgs: {
        "object": LocaleKeys.payment.plural(1),
        "action": isEdit ? LocaleKeys.edit.tr() : LocaleKeys.add.tr(),
      }),
      positiveButtonTitle: LocaleKeys.confirm.tr(),
      negativeButtonTitle: isEdit ? LocaleKeys.delete.tr() : LocaleKeys.cancel.tr(),
      onPositiveButtonPressed: onConfirmButtonPressed,
      onNegativeButtonPressed: onNegativeButtonPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic information.
          Text(
            LocaleKeys.basicInfo.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8,),
          // Name and symbol.
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: LocaleKeys.name.tr(),
              prefixIcon: IconButton(
                icon: Icon(editing.icon.icon),
                color: Theme.of(context).inputDecorationTheme.prefixIconColor,
                onPressed: () => onPaymentIconButtonPressed(),
              ),
            ),
            maxLength: BaseModel.maxTextLength,
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 8,),
          // Serial number.
          TextField(
            controller: serialNumberController,
            decoration: InputDecoration(
                labelText: LocaleKeys.serialNumber.tr(),
                prefixIcon: const Icon(Icons.numbers_outlined)
            ),
            onChanged: onSerialNumberChanged,
          ),
          const SizedBox(height: 8,),
          // Payment limitation.
          TextField(
            controller: limitationController,
            keyboardType: TextInputType.numberWithOptions(
              decimal: currency.decimalPoint > 0,
            ),
            decoration: InputDecoration(
              labelText: LocaleKeys.limitation.tr(),
              prefixIcon: IconButton(
                icon: CurrencyIcon(currency),
                onPressed: () => onCurrencyButtonPressed(),
              ),
              errorText: WalletItem.getAmountRegex(currency).hasMatch(limitationController.text)
                  ? null
                  : LocaleKeys.msgInvalidInput.tr(),
            ),
            inputFormatters: [
              FilteringTextInputFormatter(RegExp(r"[\d.]"), allow: true),
            ],
            onChanged: onLimitationChanged,
          ),
          const SizedBox(height: 8,),
          // Description.
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: LocaleKeys.description.tr(),
              prefixIcon: const Icon(Icons.notes),
            ),
            maxLines: null,
            maxLength: BaseModel.maxTextLength,
            onChanged: onDescriptionChanged,
          ),
          // Credit-payment flag.
          Padding(
            padding: const EdgeInsets.all(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onCreditValueChanged(!editing.isCredit),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Checkbox(
                      value: editing.isCredit,
                      onChanged: null,
                    ),
                    Text(
                      LocaleKeys.credit.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Credit payment schedule.
          Visibility(
            visible: editing.isCredit,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Withdrawal day.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      LocaleKeys.payDate.tr(),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    DropdownMenu<int>(
                      initialSelection: editing.payDate,
                      label: Text(LocaleKeys.day.tr()),
                      dropdownMenuEntries: List.generate(Payment.payDayMax, (index) {
                        final int value = index + 1;
                        return DropdownMenuEntry<int>(
                          value: value,
                          label: LocaleKeys.nthDay.plural(value%10, args: [value.toString()]),
                        );
                      }).toList(growable: false),
                      onSelected: onPayDateChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 8,),
                Text(
                  LocaleKeys.payRange.tr(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                // Period start.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      LocaleKeys.payRangeBegin.tr(),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Month offset.
                        DropdownMenu<int>(
                          initialSelection: editing.payBegin.month,
                          label: Text(LocaleKeys.month.tr()),
                          dropdownMenuEntries: List.generate(4, (index) {
                            return DropdownMenuEntry<int>(
                              value: index,
                              label: LocaleKeys.nMonthBefore.plural(index, args: [index.toString()]),
                            );
                          }).toList(growable: false),
                          onSelected: (value) => onPayRangeBeginChanged(value, editing.payBegin.day),
                        ),
                        const SizedBox(width: 8,),
                        // Day of month.
                        DropdownMenu<int>(
                          initialSelection: editing.payBegin.day,
                          label: Text(LocaleKeys.day.tr()),
                          dropdownMenuEntries: List.generate(Payment.payDayMax, (index) {
                            final int value = index + 1;
                            return DropdownMenuEntry<int>(
                              value: value,
                              label: LocaleKeys.nthDay.plural(value%10, args: [value.toString()]),
                            );
                          }).toList(growable: false),
                          onSelected: (value) => onPayRangeBeginChanged(editing.payBegin.month, value),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8,),
                // Period end.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      LocaleKeys.payRangeEnd.tr(),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Month offset.
                        DropdownMenu<int>(
                          initialSelection: editing.payEnd.month,
                          label: Text(LocaleKeys.month.tr()),
                          dropdownMenuEntries: List.generate(4, (index) {
                            return DropdownMenuEntry<int>(
                              value: index,
                              label: LocaleKeys.nMonthBefore.plural(index, args: [index.toString()]),
                            );
                          }).toList(growable: false),
                          onSelected: (value) => onPayRangeEndChanged(value, editing.payEnd.day),
                        ),
                        const SizedBox(width: 8,),
                        // Day of month.
                        DropdownMenu<int>(
                          initialSelection: editing.payEnd.day,
                          label: Text(LocaleKeys.day.tr()),
                          dropdownMenuEntries: List.generate(Payment.payDayMax, (index) {
                            final int value = index + 1;
                            return DropdownMenuEntry<int>(
                              value: value,
                              label: LocaleKeys.nthDay.plural(value%10, args: [value.toString()]),
                            );
                          }).toList(growable: false),
                          onSelected: (value) => onPayRangeEndChanged(editing.payEnd.month, value),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Display colors.
          Text(
            LocaleKeys.color.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          // Foreground color.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                LocaleKeys.foreground.tr(),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              IconButton(
                icon: Icon(
                  Icons.circle,
                  color: editing.foreground,
                ),
                onPressed: () => onForegroundPressed(context),
              ),
            ],
          ),
          // Background color.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                LocaleKeys.background.tr(),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              IconButton(
                icon: Icon(
                  Icons.circle,
                  color: editing.background,
                ),
                onPressed: () => onBackgroundPressed(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
