import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class PaymentEditFragment extends StatefulWidget {
  const PaymentEditFragment({
    super.key,
    required this.onFinish,
    this.base,
  });

  final Payment? base;

  final Function(Payment?) onFinish;

  @override
  _PaymentEditFragmentState createState() => _PaymentEditFragmentState();
}

class _PaymentEditFragmentState extends State<PaymentEditFragment> {

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController serialNumberController = TextEditingController();
  
  final TextEditingController limitationController = TextEditingController();

  /// Is this fragment editing [Payment]
  ///
  /// This returns `true` when [widget.base] is not `null`
  bool get isEdit => widget.base != null;

  /// [Payment] which is now editing
  Payment editing = Payment({});

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

  /// Show [T] item selection dialog
  Future<T> showSelectDialog<T>(BuildContext context, String title, List<T> list) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: (MediaQuery.of(context).size.width / InterfaceConstructor.panelNumber(context)) * 0.8,
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
                    icon = Text(
                      item.symbol,
                      style: Theme.of(context).textTheme.titleMedium,
                    );
                    break;
                  case PaymentSymbol:
                    title = (item as PaymentSymbol).key.tr();
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
        return AlertDialog(
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selected,
              onColorChanged: (value) => selected = value,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selected),
              child: Text(LocaleKeys.confirm.tr()),
            ),
          ],
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
    final ApiResponse<List<Payment>> result = await ApiClient().delete([widget.base!.map]);
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
    late ApiResponse<List<Payment>> result;
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
  void onLimitationChanged(String lim) {
    editing.limitation = Decimal.parse(lim);
    setState(() {});
  }

  /// Triggers on [PaymentIcon] button pressed
  void onPaymentIconButtonPressed() async {
    final icon = await showSelectDialog<PaymentSymbol>(
      context,
      LocaleKeys.icon.tr(),
      PaymentSymbol.values,
    );
    editing.icon = icon;
    setState(() {});
  }

  /// Triggers on [Currency] button pressed
  void onCurrencyButtonPressed() async {
    final currency = await showSelectDialog<Currency>(
      context,
      LocaleKeys.icon.tr(),
      Currency.values,
    );
    editing.currency = currency;
    setState(() {});
  }

  /// Triggers on cash checkboxes value changed
  void onCreditValueChanged(bool value) {
    editing.isCredit = value;
    setState(() {});
  }

  /// Triggers on payment range begin value changed
  void onPayRangeBeginChanged(int? month, int? day) {
    if (month == null || day == null) {
      return;
    }
    editing.payBegin = PaymentRangePoint(month, day);
    setState(() {});
  }

  /// Triggers on payment range end value changed
  void onPayRangeEndChanged(int? month, int? day) {
    if (month == null || day == null) {
      return;
    }
    editing.payEnd = PaymentRangePoint(month, day);
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
    editing = widget.base ?? Payment({});
    descriptionController.text = editing.descriptions;
    serialNumberController.text = editing.serialNumber;
    limitationController.text = editing.limitation.toString();
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
              "object": LocaleKeys.payment.plural(1),
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
                        onPressed: () => onPaymentIconButtonPressed(),
                      )
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
                  inputFormatters: [
                    FilteringTextInputFormatter(RegExp(r'[\d\s.:;_,/*#()]'), allow: true),
                  ],
                  onChanged: onSerialNumberChanged,
                ),
                const SizedBox(height: 8,),
                // Limitation
                TextField(
                  controller: limitationController,
                  decoration: InputDecoration(
                      labelText: LocaleKeys.limitation.tr(),
                      prefixIcon: IconButton(
                        icon: Text(editing.currency.symbol),
                        onPressed: () => onCurrencyButtonPressed(),
                      )
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(32),
                    FilteringTextInputFormatter(RegExp(r'[\d.]'), allow: true),
                  ],
                  onChanged: onLimitationChanged,
                ),
                // Is cash checkbox
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Checkbox(
                        value: editing.isCredit,
                        onChanged: (value) => onCreditValueChanged(value ?? false),
                      ),
                      Text(
                        LocaleKeys.credit.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                // Payment
                Visibility(
                  visible: editing.isCredit,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
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
                                label: LocaleKeys.nDay.plural(value%10, args: [value.toString()]),
                              );
                            }).toList(growable: false),
                            onSelected: (value) => onPayRangeBeginChanged(editing.payDate, value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8,),
                      Text(
                        LocaleKeys.payRange.tr(),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      // From
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
                              // Month
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
                              // Day
                              DropdownMenu<int>(
                                initialSelection: editing.payBegin.day,
                                label: Text(LocaleKeys.day.tr()),
                                dropdownMenuEntries: List.generate(Payment.payDayMax, (index) {
                                  final int value = index + 1;
                                  return DropdownMenuEntry<int>(
                                    value: value,
                                    label: LocaleKeys.nDay.plural(value%10, args: [value.toString()]),
                                  );
                                }).toList(growable: false),
                                onSelected: (value) => onPayRangeBeginChanged(editing.payBegin.month, value),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8,),
                      // To
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
                              // Month
                              DropdownMenu<int>(
                                initialSelection: editing.payEnd.month,
                                label: Text(LocaleKeys.month.tr()),
                                dropdownMenuEntries: List.generate(4, (index) {
                                  return DropdownMenuEntry<int>(
                                    value: index,
                                    label: LocaleKeys.nMonthBefore.plural(index, args: [index.toString()]),
                                  );
                                }).toList(growable: false),
                                onSelected: (value) => onPayRangeEndChanged(value, editing.payBegin.day),
                              ),
                              const SizedBox(width: 8,),
                              // Day
                              DropdownMenu<int>(
                                initialSelection: editing.payEnd.day,
                                label: Text(LocaleKeys.day.tr()),
                                dropdownMenuEntries: List.generate(Payment.payDayMax, (index) {
                                  final int value = index + 1;
                                  return DropdownMenuEntry<int>(
                                    value: value,
                                    label: LocaleKeys.nDay.plural(value%10, args: [value.toString()]),
                                  );
                                }).toList(growable: false),
                                onSelected: (value) => onPayRangeEndChanged(editing.payBegin.month, value),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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
                      icon: const Icon(Icons.circle),
                      color: editing.foreground,
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
                      icon: const Icon(Icons.circle),
                      color: editing.background,
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
    );
  }
}