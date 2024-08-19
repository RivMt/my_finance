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

class AccountEditFragment extends ConsumerStatefulWidget {
  const AccountEditFragment({
    super.key,
    required this.onFinish,
    this.base,
  });

  final Account? base;

  final Function(Account?) onFinish;

  @override
  ConsumerState createState() => _AccountEditFragmentState();
}

class _AccountEditFragmentState extends ConsumerState<AccountEditFragment> {

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
    return colors;
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
                    icon = Icon(item.icon);
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
  void onNegativeButtonPressed() async {
    // Escape on creating mode
    if (!isEdit) {
      widget.onFinish(null);
    }
    progressing = true;
    final ApiResponse<List<Account>> result = await ApiClient().delete([widget.base!.map]);
    progressing = false;
    // Check failed
    if (result.result != ApiResultCode.success && result.data.length != 1) {
      return;
    }
    // Complete
    widget.onFinish(result.data[0]);
  }

  /// Triggers on confirm button pressed
  void onConfirmButtonPressed() async {
    late ApiResponse<List<Account>> result;
    progressing = true;
    // Send
    if (isEdit) {
      result = await ApiClient().update([editing.map]);
    } else {
      result = await ApiClient().create([editing.map]);
    }
    // Check
    progressing = false;
    if (result.result != ApiResultCode.success || result.data.length != 1) {
      // Failed
      return;
    }
    // Complete
    widget.onFinish(result.data[0]);
  }

  /// Triggers on description changed
  void onDescriptionChanged(String desc) {
    editing.descriptions = desc;
    setState(() {});
  }

  /// Triggers on description changed
  void onSerialNumberChanged(String serial) {
    editing.serialNumber = serial;
    setState(() {});
  }

  /// Triggers on limitation changed
  void onLimitationChanged(String value) {
    if (editing.regex.hasMatch(value)) {
      if (value != "") {
        editing.limitation = Decimal.parse(value);
      }
    }
    setState(() {});
  }

  /// Triggers on [AccountIcon] button pressed
  void onAccountIconButtonPressed() async {
    final icon = await showSelectDialog<AccountSymbol>(
      context,
      LocaleKeys.icon.tr(),
      AccountSymbol.values,
    );
    if (icon != null) {
      editing.icon = icon;
      setState(() {});
    }
  }

  /// Triggers on [Currency] button pressed
  void onCurrencyButtonPressed() async {
    final currency = await showSelectDialog<Currency>(
      context,
      LocaleKeys.icon.tr(),
      Currency.values,
    );
    if (currency != null) {
      editing.currency = currency;
      setState(() {});
    }
  }

  /// Triggers on cash checkboxes value changed
  void onCashValueChanged(bool value) {
    editing.isCash = value;
    setState(() {});
  }

  /// Triggers on foreground color button pressed
  void onForegroundPressed(BuildContext context) async {
    editing.foreground = await showColorPicker(context, editing.foreground);
    setState(() {});
  }

  /// Triggers on background color button pressed
  void onBackgroundPressed(BuildContext context) async {
    editing.background = await showColorPicker(context, editing.background);
    setState(() {});
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
              disabled: progressing || !ready,
              headerTitle: LocaleKeys.object_action.tr(namedArgs: {
                "object": LocaleKeys.account.plural(1),
                "action": isEdit ? LocaleKeys.edit.tr() : LocaleKeys.add.tr(),
              }),
              positiveButtonTitle: LocaleKeys.confirm.tr(),
              negativeButtonTitle: isEdit ? LocaleKeys.delete.tr() : LocaleKeys.cancel.tr(),
              onPositiveButtonPressed: progressing ? null : onConfirmButtonPressed,
              onNegativeButtonPressed: progressing ? null : onNegativeButtonPressed,
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
                      decimal: editing.currency.decimalDigits > 0,
                    ),
                    decoration: InputDecoration(
                      labelText: LocaleKeys.limitation.tr(),
                      prefixIcon: IconButton(
                        icon: Icon(editing.currency.icon),
                        onPressed: () => onCurrencyButtonPressed(),
                      ),
                      errorText: editing.regex.hasMatch(limitationController.text)
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