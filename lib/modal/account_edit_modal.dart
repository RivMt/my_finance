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

/// Creates, updates, or soft-deletes an [Account].
class AccountEditModal extends ConsumerStatefulWidget {
  const AccountEditModal(this.base, {super.key});

  /// Account to edit, or `null` when creating one.
  final Account? base;

  @override
  ConsumerState createState() => _AccountEditModalState();
}

class _AccountEditModalState extends ConsumerState<AccountEditModal> {
  final TextEditingController nameController = TextEditingController();

  final TextEditingController serialNumberController = TextEditingController();

  final TextEditingController limitationController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  /// Whether an existing account is being edited.
  bool get isEdit => widget.base != null;

  /// Mutable account being edited.
  Account editing = Account({});

  /// Whether the account and limitation input are valid.
  bool get ready {
    return editing.isValid &&
        (limitationController.text == editing.limitation.toString());
  }

  /// Builds a recent-color list from accounts and payments.
  List<Color> buildColorHistory() {
    List<Color> colors = [];
    // Account colors, newest first.
    final accounts = ref.watch(provider.accounts);
    accounts.sort((a, b) {
      return b.modifiedAt.millisecondsSinceEpoch -
          a.modifiedAt.millisecondsSinceEpoch;
    });
    for (Account account in accounts) {
      colors.add(account.foreground);
      colors.add(account.background);
    }
    // Payment colors, newest first.
    final payments = ref.watch(provider.payments);
    payments.sort((a, b) {
      return b.modifiedAt.millisecondsSinceEpoch -
          a.modifiedAt.millisecondsSinceEpoch;
    });
    for (Payment payment in payments) {
      colors.add(payment.foreground);
      colors.add(payment.background);
    }
    return colors.toSet().toList();
  }

  /// Shows the [AccountSymbol] selection dialog.
  Future<AccountSymbol?> showSymbolSelectDialog(BuildContext context) async {
    const list = AccountSymbol.values;
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
        });
    return result ?? color;
  }

  /// Deletes the account in edit mode or cancels creation.
  Future<bool> onNegativeButtonPressed() async {
    if (!isEdit) {
      return true;
    }
    return await provider.deleteAccount(ref, editing);
  }

  /// Persists the account being edited.
  Future<bool> onConfirmButtonPressed() async {
    if (isEdit) {
      return await provider.updateAccount(ref, editing);
    }
    return await provider.createAccount(ref, editing);
  }

  /// Updates the account name.
  void onNameChanged(String text) {
    setState(() {
      editing.name = text;
    });
  }

  /// Updates the account serial number.
  void onSerialNumberChanged(String serial) {
    setState(() {
      editing.serialNumber = serial;
    });
  }

  /// Updates the account limitation when [value] is valid.
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

  /// Updates the account description.
  void onDescriptionChanged(String text) {
    setState(() {
      editing.descriptions = text;
    });
  }

  /// Selects the account symbol.
  void onAccountIconButtonPressed() async {
    final icon = await showSymbolSelectDialog(context);
    if (icon != null) {
      setState(() {
        editing.icon = icon;
      });
    }
  }

  /// Selects the account currency.
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

  /// Updates whether the account holds cash.
  void onCashValueChanged(bool value) {
    setState(() {
      editing.isCash = value;
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
    editing = widget.base ?? Account({});
    nameController.text = editing.name;
    serialNumberController.text = editing.serialNumber;
    limitationController.text = editing.limitation.toString();
    descriptionController.text = editing.descriptions;
  }

  @override
  Widget build(BuildContext context) {
    final currency = provider.getCurrency(ref, editing.currencyId);
    return Modal(
      ready: ready,
      title: LocaleKeys.object_action.tr(namedArgs: {
        "object": LocaleKeys.account.plural(1),
        "action": isEdit ? LocaleKeys.edit.tr() : LocaleKeys.add.tr(),
      }),
      positiveButtonTitle: LocaleKeys.confirm.tr(),
      negativeButtonTitle:
          isEdit ? LocaleKeys.delete.tr() : LocaleKeys.cancel.tr(),
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
          const SizedBox(
            height: 8,
          ),
          // Name and symbol.
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: LocaleKeys.name.tr(),
              prefixIcon: IconButton(
                icon: Icon(editing.icon.icon),
                color: Theme.of(context).inputDecorationTheme.prefixIconColor,
                onPressed: () => onAccountIconButtonPressed(),
              ),
            ),
            maxLength: BaseModel.maxTextLength,
            onChanged: onNameChanged,
          ),
          const SizedBox(
            height: 8,
          ),
          // Serial number.
          TextField(
            controller: serialNumberController,
            decoration: InputDecoration(
                labelText: LocaleKeys.serialNumber.tr(),
                prefixIcon: const Icon(Icons.numbers_outlined)),
            onChanged: onSerialNumberChanged,
          ),
          const SizedBox(
            height: 8,
          ),
          // Account limitation.
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
              errorText: WalletItem.getAmountRegex(currency)
                      .hasMatch(limitationController.text)
                  ? null
                  : LocaleKeys.msgInvalidInput.tr(),
            ),
            inputFormatters: [
              FilteringTextInputFormatter(RegExp(r"[\d.]"), allow: true),
            ],
            onChanged: onLimitationChanged,
          ),
          const SizedBox(
            height: 8,
          ),
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
          // Cash-account flag.
          Padding(
            padding: const EdgeInsets.all(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onCashValueChanged(!editing.isCash),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Checkbox(
                      value: editing.isCash,
                      onChanged: null,
                    ),
                    Text(
                      LocaleKeys.cash.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
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
