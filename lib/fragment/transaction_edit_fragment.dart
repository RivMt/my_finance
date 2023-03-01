import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/dialog/category_select_dialog.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

const String _tag = "TransactionEditFragment";

final _accounts = StateNotifierProvider<ModelsState<Account>, List<Account>>((ref) {
  return ModelsState<Account>(ref);
});

final _payments = StateNotifierProvider<ModelsState<Payment>, List<Payment>>((ref) {
  return ModelsState<Payment>(ref);
});

final _categories = StateNotifierProvider<ModelsState<Category>, List<Category>>((ref) {
  return ModelsState<Category>(ref);
});

class TransactionEditFragment extends ConsumerStatefulWidget {
  const TransactionEditFragment({
    super.key,
    required this.onFinish,
    this.isEdit = false,
    this.base,
  });

  final Transaction? base;

  /// Value of this fragment is editing [Transaction]
  final bool isEdit;

  final Function(Transaction?) onFinish;

  @override
  ConsumerState createState() => _TransactionEditFragmentState();
}

class _TransactionEditFragmentState extends ConsumerState<TransactionEditFragment> {

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController amountController = TextEditingController();

  final TextEditingController altAmountController = TextEditingController();

  final TextEditingController utilityDaysController = TextEditingController();

  /// Is this fragment editing [Transaction]
  ///
  /// This returns `true` when [widget.base] is not `null`
  bool get isEdit => widget.isEdit;

  /// [Transaction] which is now editing
  Transaction editing = Transaction({});

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

  /// Currently selected [Account]
  Account get selectedAccount {
    return ref.watch(_accounts).firstWhere((item) => item.pid == editing.accountId, orElse: () => Account.unknown);
  }

  /// Currently selected [Payment]
  Payment get selectedPayment {
    return ref.watch(_payments).firstWhere((item) => item.pid == editing.paymentId, orElse: () {
      if (editing.paymentId == Payment.none.pid) {
        return Payment.none;
      }
      return Payment.unknown;
    });
  }

  /// Currently selected [Category]
  Category get selectedCategory {
    return ref.watch(_categories).firstWhere((item) => item.pid == editing.category, orElse: () => Category.unknown);
  }

  /// Request
  void request() async {
    // Account
    await ref.read(_accounts.notifier).request([{
      ModelKeys.keyDeleted: false,
    }], ApiClient.buildOptions(
      sorts: [
        const Sort(ModelKeys.keyPriority, SortType.desc),
      ],
    ));
    final account = selectedAccount;
    setAccount(account);
    // Payment
    await ref.read(_payments.notifier).request([{
      ModelKeys.keyDeleted: false,
    }], ApiClient.buildOptions(
      sorts: [
        const Sort(ModelKeys.keyPriority, SortType.desc),
      ],
    ));
    final payment = selectedPayment;
    setPayment(payment);
    // Category
    await ref.read(_categories.notifier).request([{
      ModelKeys.keyDeleted: false,
    }], ApiClient.buildOptions(
      sorts: [
        const Sort(ModelKeys.keyLastUsed, SortType.desc),
      ],
    ));
    final category = selectedCategory;
    setCategory(category);
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
                switch(T) {
                  case Account:
                    return AccountCard(
                      data: item as Account,
                      showBalance: false,
                      onTap: () => Navigator.pop(context, item),
                    );
                  case Payment:
                    return PaymentCard(
                      data: item as Payment,
                      onTap: () => Navigator.pop(context, item),
                    );
                  default:
                    return const SizedBox();
                }
              },
            ),
          ),
        );
      },
    );
  }

  /// Show [Category] item selection dialog
  Future<Category?> showCategorySelectDialog(BuildContext context, List<Category> list) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return CategorySelectDialog(
          list: list,
          onTap: (item) => Navigator.pop(context, item),
        );
      },
    );
  }
  
  /// Show date picker
  Future<DateTime> showDatePickDialog(BuildContext context, DateTime base) async {
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.fromMillisecondsSinceEpoch(0),
      lastDate: Model.maxDate,
    );
    return result ?? base;
  }

  /// Triggers on negative button pressed
  void onNegativeButtonPressed() async {
    // Escape on creating mode
    if (!isEdit) {
      widget.onFinish(null);
    }
    progressing = true;
    final ApiResponse<List<Transaction>> result = await ApiClient().delete([widget.base!.map]);
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
    // Check transaction is valid
    if (!editing.isValid) {
      return;
    }
    late ApiResponse<List<Transaction>> result;
    progressing = true;
    // Send
    if (isEdit) {
      result = await ApiClient().update([editing.map]);
      Log.v(_tag, "Update: ${editing.map}");
    } else {
      result = await ApiClient().create([editing.map]);
      Log.v(_tag, "Create: ${editing.map}");
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

  /// Set [editing.paidDate]
  void setPaidDate(DateTime date) {
    editing.paidDate = date;
    setCalculatedDate();
  }

  /// Set [editing.calculatedDate]
  ///
  /// If [date] is not `null`, set [editing.calculatedDate] to [date]. And
  /// [date] is `null` and [editing.calculatedDate] is equal to
  /// [Transaction.defaultCalculatedDate], set it from [editing.paidDate].
  ///
  /// Make [override] `true` to override [editing.calculatedDate] whether its value.
  void setCalculatedDate([DateTime? date]) {
    if (date != null) {
      editing.calculatedDate = date;
      return;
    }
    final payment = selectedPayment;
    editing.calculatedDate = payment.getCalculatedDate(editing.paidDate);
  }

  /// Set [editing.accountId] and [editing.currency]
  void setAccount(Account account) {
    editing.accountId = account.pid;
    editing.currency = account.currency;
    setState(() {});
  }

  /// Set [editing.paymentId], [editing.altCurrency], [editing.altAmount] and
  /// [editing.calculatedDate].
  void setPayment(Payment payment) {
    editing.paymentId = payment.pid;
    if (payment.currency != Currency.unknown && payment.currency != editing.currency) {
      editing.altCurrency = payment.currency;
      editing.altAmount = Decimal.zero;
    } else {
      editing.altCurrency = null;
      editing.altAmount = null;
    }
    setCalculatedDate();
  }

  /// Set [editing.category] and [editing.type]
  void setCategory(Category category) {
    editing.category = category.pid;
    editing.type = category.type;
    editing.isIncluded = category.isIncluded;
    if (editing.type != TransactionType.expense) {
      onNoPaymentCheckboxChanged(true);
    }
  }

  /// Triggers on paid date button pressed
  void onPaidDateButtonPressed(BuildContext context) async {
    final date = await showDatePickDialog(context, editing.paidDate);
    setPaidDate(date);
    setState(() {});
  }

  /// Triggers on calculated date button pressed
  void onCalculatedDateButtonPressed(BuildContext context) async {
    final date = await showDatePickDialog(context, editing.calculatedDate);
    setCalculatedDate(date);
    setState(() {});
  }

  /// Triggers on category card tapped
  void onCategoryCardTapped(List<Category> categories) async {
    final category = await showCategorySelectDialog(context, categories);
    if (category != null) {
      setCategory(category);
    }
    setState(() {});
  }
  
  /// Triggers on account card tapped
  void onAccountCardTapped(List<Account> accounts) async {
    final account = await showSelectDialog(context, LocaleKeys.object_action.tr(namedArgs: {
      "object": LocaleKeys.account.plural(1),
      "action": LocaleKeys.select.tr(),
    }), accounts);
    if (account != null) {
      setAccount(account);
    }
    setPayment(selectedPayment);
    setState(() {});
  }

  /// Triggers on no payment checkbox changed
  void onNoPaymentCheckboxChanged(bool value) {
    setPayment(value ? Payment.none : Payment.unknown);
    setState(() {});
  }

  /// Triggers on payment card tapped
  void onPaymentCardTapped(List<Payment> payments) async {
    final payment = await showSelectDialog(context, LocaleKeys.object_action.tr(namedArgs: {
      "object": LocaleKeys.payment.plural(1),
      "action": LocaleKeys.select.tr(),
    }), payments);
    if (payment != null) {
      setPayment(payment);
    }
    setAccount(selectedAccount);
    setState(() {});
  }

  /// Triggers on alt amount changed
  void onAltAmountChanged(String value) {
    if (editing.regex.hasMatch(value)) {
      editing.altAmount = value == "" ? Decimal.zero :Decimal.parse(value);
    } else {
      altAmountController.text = editing.altAmount.toString();
    }
    setState(() {});
  }

  /// Triggers on amount changed
  void onAmountChanged(String value) {
    if (editing.regex.hasMatch(value)) {
      editing.amount = value == "" ? Decimal.zero :Decimal.parse(value);
    } else {
      amountController.text = editing.amount.toString();
    }
    setState(() {});
  }

  /// Triggers on description changed
  void onDescriptionChanged(String desc) {
    editing.descriptions = desc;
    setState(() {});
  }

  /// Triggers on cash checkboxes value changed
  void onIncludedValueChanged(bool value) {
    editing.isIncluded = value;
    setState(() {});
  }

  /// Triggers on utility days calculate button pressed
  void onUtilityDaysCalculateButtonPressed(BuildContext context) async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: editing.paidDate,
        end: editing.utilityEnd,
      ),
      firstDate: editing.paidDate,
      lastDate: Model.maxDate,
    );
    if (range == null) {
      return;
    }
    editing.utilityDays = range.duration.inDays + 1;
    utilityDaysController.text = editing.utilityDays.toString();
    setState(() {});
  }

  /// Triggers on utility days value changed
  void onUtilityDaysValueChanged(String value) {
    if (value.isEmpty) {
      editing.utilityDays = 1;
    }
    editing.utilityDays = int.parse(value);
  }

  /// Apply [editing] data to UI
  void apply() {
    descriptionController.text = editing.descriptions;
    amountController.text = editing.amount.toString();
    altAmountController.text = (editing.altAmount ?? Decimal.zero).toString();
    utilityDaysController.text = editing.utilityDays.toString();
  }

  @override
  void initState() {
    super.initState();
    assert((widget.isEdit && widget.base != null) || !widget.isEdit);
    editing = widget.base ?? Transaction.init();
    request();
    apply();
  }

  @override
  void didUpdateWidget(TransactionEditFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
    apply();
  }

  @override
  Widget build(BuildContext context) {
    final category = selectedCategory;
    final account = selectedAccount;
    final payment = selectedPayment;
    final bool useAlt = (payment != Payment.none) &&
        (account != Account.unknown) &&
        (editing.altCurrency != null) &&
        (editing.altCurrency != editing.currency);
    return SingleChildScrollView(
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
              disabled: progressing || !editing.isValid,
              headerTitle: LocaleKeys.object_action.tr(namedArgs: {
                "object": LocaleKeys.transaction.plural(1),
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
                        payment.isCredit
                            ? LocaleKeys.transactionDate.tr()
                            : LocaleKeys.paidDate.tr(),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onPaidDateButtonPressed(context),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                DateFormat.yMd().format(editing.paidDate),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(width: 8,),
                              Icon(
                                Icons.calendar_today_outlined,
                                color: Theme.of(context).primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8,),
                  Visibility(
                    visible: payment.isCredit,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          LocaleKeys.paidDate.tr(),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => onCalculatedDateButtonPressed(context),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  DateFormat.yMd().format(editing.calculatedDate),
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(width: 8,),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8,),
                  // Category
                  Text(
                    LocaleKeys.category.plural(1),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  CategoryCard(
                    category: category,
                    unknownMessage: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
                      "object": LocaleKeys.category.plural(1),
                    }),
                    onTap: () => onCategoryCardTapped(ref.watch(_categories)),
                  ),
                  const SizedBox(height: 8,),
                  // Account
                  Text(
                    LocaleKeys.account.plural(1),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  AccountCard(
                    data: account,
                    showBalance: false,
                    unknownMessage: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
                      "object": LocaleKeys.account.plural(1),
                    }),
                    onTap: () => onAccountCardTapped(ref.watch(_accounts)),
                  ),
                  const SizedBox(height: 8,),
                  // Payment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        LocaleKeys.payment.plural(1),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Checkbox(
                            value: payment == Payment.none,
                            tristate: false,
                            onChanged: (value) => onNoPaymentCheckboxChanged(value!),
                          ),
                          Text(
                            LocaleKeys.noPayment.plural(1),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      )
                    ],
                  ),
                  Visibility(
                    visible: payment != Payment.none,
                    child: PaymentCard(
                      data: payment,
                      unknownMessage: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
                        "object": LocaleKeys.payment.plural(1),
                      }),
                      onTap: () => onPaymentCardTapped(ref.watch(_payments)),
                    ),
                  ),
                  const SizedBox(height: 8,),
                  // Basic information
                  Text(
                    LocaleKeys.basicInfo.tr(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8,),
                  // Alt amount
                  Visibility(
                    visible: useAlt,
                    child: TextField(
                      controller: altAmountController,
                      decoration: InputDecoration(
                        labelText: LocaleKeys.paidAmount.tr(),
                        prefixIcon: IconButton(
                          icon: Icon(editing.altCurrency == null ? CurrencySymbol.sign : editing.altCurrency!.icon),
                          onPressed: () {},
                        ),
                      ),
                      onChanged: onAltAmountChanged,
                    ),
                  ),
                  const SizedBox(height: 8,),
                  // Amount
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: useAlt ? LocaleKeys.withdrawAmount.tr() : LocaleKeys.paidAmount.tr(),
                      prefixIcon: IconButton(
                        icon: Icon(editing.currency.icon),
                        onPressed: () {},
                      ),
                    ),
                    onChanged: onAmountChanged,
                  ),
                  const SizedBox(height: 8,),
                  // Description
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.description.tr(),
                      prefixIcon: const Icon(Icons.notes),
                    ),
                    onChanged: onDescriptionChanged,
                  ),
                  const SizedBox(height: 8,),
                  // Efficient days
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          LocaleKeys.utilityDays.tr(),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: utilityDaysController,
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            labelText: LocaleKeys.utilityDays.tr(),
                            prefixIcon: IconButton(
                              icon: const Icon(Icons.calendar_month_outlined),
                              onPressed: () => onUtilityDaysCalculateButtonPressed(context),
                            ),
                            suffixText: LocaleKeys.day.plural(
                              editing.utilityDays%10,
                              args: [editing.utilityDays.toString()],
                            ),
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(5),
                            FilteringTextInputFormatter(RegExp(r"\d"), allow: true),
                          ],
                          onChanged: onUtilityDaysValueChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8,),
                  // Included checkbox
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Checkbox(
                          value: editing.isIncluded,
                          onChanged: (value) => onIncludedValueChanged(value ?? false),
                        ),
                        Text(
                          LocaleKeys.included.tr(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
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