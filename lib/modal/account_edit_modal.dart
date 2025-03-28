import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/dialog/color_picker_dialog.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class AccountEditModal extends ConsumerStatefulWidget {
  const AccountEditModal({
    super.key,
    required this.onFinish,
    this.base,
  });

  final Account? base;

  final Function(Account?) onFinish;

  @override
  ConsumerState createState() => _AccountEditModalState();
}

class _AccountEditModalState extends ConsumerState<AccountEditModal> {

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController serialNumberController = TextEditingController();
  
  final TextEditingController limitationController = TextEditingController();

  /// Is this fragment editing [Account]
  ///
  /// This returns `true` when [widget.base] is not `null`
  bool get isEdit => widget.base != null;

  /// [Account] which is now editing
  Account editing = Account({});

  /// Value of [editing] is ready or not
  bool get ready {
    return editing.isValid
        && (limitationController.text == editing.limitation.toString());
  }

  /// Build list of colors
  List<Color> buildColorHistory() {
    List<Color> colors = [];
    // Colors of accounts
    final accounts = ref.watch(provider.accounts);
    accounts.sort((a, b) {
      return b.lastUsed.millisecondsSinceEpoch - a.lastUsed.millisecondsSinceEpoch;
    });
    for (Account account in accounts) {
      colors.add(account.foreground);
      colors.add(account.background);
    }
    // Colors of payments
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

  /// Show [T] item selection dialog
  Future<T?> showSelectDialog<T>(BuildContext context, String title, List<T> list) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: ScreenPlanner(context).dialogWidth,
            height: MediaQuery.of(context).size.height * 0.7,
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                late String title;
                late Widget icon;
                switch(T) {
                  case Currency:
                    title = (item as Currency).key.tr();
                    icon = CurrencyIcon(item);
                    break;
                  case AccountSymbol:
                    title = (item as AccountSymbol).key.tr();
                    icon = Icon(item.icon);
                    break;
                  default:
                    title = "Unknown";
                    icon = const Text('?');
                }
                return ListTile(
                  title: Text(title),
                  leading: icon,
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Show color picker dialog
  ///
  /// [color] is selected color on pop up
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

  /// Triggers on negative button pressed
  Future<bool> onNegativeButtonPressed() async {
    // Escape on creating mode
    if (!isEdit) {
      widget.onFinish(null);
    }
    final ApiResponse<List<Account>> result = await ApiClient().delete(Account.endpoint, widget.base!.uuid);
    // Check failed
    if (result.result != ApiResultCode.success && result.data.length != 1) {
      return false;
    }
    // Complete
    widget.onFinish(result.data[0]);
    return true;
  }

  /// Triggers on confirm button pressed
  Future<bool> onConfirmButtonPressed() async {
    late ApiResponse<List<Account>> result;
    // Send
    if (isEdit) {
      result = await ApiClient().update(Account.endpoint, editing.map);
    } else {
      result = await ApiClient().create(Account.endpoint, editing.map);
    }
    // Check
    if (result.result != ApiResultCode.success || result.data.length != 1) {
      // Failed
      return false;
    }
    // Complete
    widget.onFinish(result.data[0]);
    return true;
  }

  /// Triggers on description changed
  void onDescriptionChanged(String desc) {
    setState(() {
      editing.descriptions = desc;
    });
  }

  /// Triggers on description changed
  void onSerialNumberChanged(String serial) {
    setState(() {
      editing.serialNumber = serial;
    });
  }

  /// Triggers on limitation changed
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

  /// Triggers on [AccountIcon] button pressed
  void onAccountIconButtonPressed() async {
    final icon = await showSelectDialog<AccountSymbol>(
      context,
      LocaleKeys.icon.tr(),
      AccountSymbol.values,
    );
    if (icon != null) {
      setState(() {
        editing.icon = icon;
      });
    }
  }

  /// Triggers on [Currency] button pressed
  void onCurrencyButtonPressed() async {
    final currencies = ref.watch(provider.currencies);
    final currency = await showSelectDialog<Currency>(
      context,
      LocaleKeys.icon.tr(),
      currencies,
    );
    if (currency != null) {
      setState(() {
        editing.currencyId = currency.uuid;
      });
    }
  }

  /// Triggers on cash checkboxes value changed
  void onCashValueChanged(bool value) {
    setState(() {
      editing.isCash = value;
    });
  }

  /// Triggers on foreground color button pressed
  void onForegroundPressed(BuildContext context) async {
    final value = await showColorPicker(context, editing.foreground);
    setState(() {
      editing.foreground = value;
    });
  }

  /// Triggers on background color button pressed
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
    descriptionController.text = editing.descriptions;
    serialNumberController.text = editing.serialNumber;
    limitationController.text = editing.limitation.toString();
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
      negativeButtonTitle: isEdit ? LocaleKeys.delete.tr() : LocaleKeys.cancel.tr(),
      onPositiveButtonPressed: onConfirmButtonPressed,
      onNegativeButtonPressed: onNegativeButtonPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic information
          Text(
            LocaleKeys.basicInfo.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8,),
          // Description
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: LocaleKeys.name.tr(),
              prefixIcon: IconButton(
                icon: Icon(editing.icon.icon),
                onPressed: () => onAccountIconButtonPressed(),
              ),
            ),
            onChanged: onDescriptionChanged,
          ),
          const SizedBox(height: 8,),
          // Serial Number
          TextField(
            controller: serialNumberController,
            decoration: InputDecoration(
                labelText: LocaleKeys.serialNumber.tr(),
                prefixIcon: const Icon(Icons.numbers_outlined)
            ),
            onChanged: onSerialNumberChanged,
          ),
          const SizedBox(height: 8,),
          // Limitation
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
                  : LocaleKeys.msgInvalidInput,
            ),
            inputFormatters: [
              FilteringTextInputFormatter(RegExp(r"[\d.]"), allow: true),
            ],
            onChanged: onLimitationChanged,
          ),
          // Is cash checkbox
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
          // Color
          Text(
            LocaleKeys.color.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          // Foreground
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
          // Background
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