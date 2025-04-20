import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/dialog/category_select_dialog.dart';
import 'package:my_finance/dialog/select_dialog.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

final _filteredAccounts = Provider<List<Account>>((ref) {
  final min = ref.watch(_minPriorityFilter);
  final max = ref.watch(_maxPriorityFilter);
  final sort = ref.watch(_sortFilter);
  final list = ref.watch(provider.accounts);
  List<Account> result = list.where((account) {
        return account.priority >= min
            && account.priority <= max
            && !account.deleted;
  }).toList();
  if (Account.unknown.map.containsKey(sort)) {
    result.sort((a1, a2) =>
        (a1.map[sort] as Comparable).compareTo(a2.map[sort]));
  }
  return result;
});

final _filteredPayments = Provider<List<Payment>>((ref) {
  final min = ref.watch(_minPriorityFilter);
  final max = ref.watch(_maxPriorityFilter);
  final sort = ref.watch(_sortFilter);
  final list = ref.watch(provider.payments);
  List<Payment> result = list.where((payment) {
        return payment.priority >= min
            && payment.priority <= max
            && !payment.deleted;
  }).toList();
  if (Payment.unknown.map.containsKey(sort)) {
    result.sort((a1, a2) =>
        (a1.map[sort] as Comparable).compareTo(a2.map[sort]));
  }
  return result;
});

final _minPriorityFilter = StateNotifierProvider<ModelState<int>, int>((ref) {
  return ModelState<int>(ref, 0);
});

final _maxPriorityFilter = StateNotifierProvider<ModelState<int>, int>((ref) {
  return ModelState<int>(ref, 1000);
});

final _sortFilter = StateNotifierProvider<ModelState<String>, String>((ref) {
  return ModelState<String>(ref, ModelKeys.keyLastUsed);
});

class TransactionEditModal extends ConsumerStatefulWidget {
  const TransactionEditModal({
    super.key,
    this.base,
    this.account,
    this.payment,
  });

  final Transaction? base;

  final Account? account;

  final Payment? payment;

  @override
  ConsumerState createState() => _TransactionEditModalState();
}

class _TransactionEditModalState extends ConsumerState<TransactionEditModal> {

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController amountController = TextEditingController();

  final TextEditingController altAmountController = TextEditingController();

  final TextEditingController utilityDaysController = TextEditingController();

  /// Is this fragment editing [Transaction]
  ///
  /// This returns `true` when [widget.base] is not `null`
  bool get isEdit => widget.base != null;

  /// [Transaction] which is now editing
  Transaction editing = Transaction({});

  /// Value of [editing] is ready or not
  bool get ready {
    return editing.isValid
        && (amountController.text == editing.amount.toString())
        && (altAmountController.text == editing.altAmount.toString() || editing.altAmount == null)
        && (descriptionController.text == editing.descriptions)
        && (utilityDaysController.text == editing.utilityDays.toString());
  }

  /// Currently selected [Account]
  Account get selectedAccount {
    return ref.watch(_filteredAccounts).firstWhere((item) => item.uuid == editing.accountId, orElse: () => Account.unknown);
  }

  /// Currently selected [Payment]
  Payment get selectedPayment {
    return ref.watch(_filteredPayments).firstWhere((item) => item.uuid == editing.paymentId, orElse: () {
      if (editing.paymentId == Payment.none.uuid) {
        return Payment.none;
      }
      return Payment.unknown;
    });
  }

  /// Currently selected [Category]
  Category get selectedCategory {
    return ref.watch(provider.categories).firstWhere((item) => item.uuid == editing.categoryId, orElse: () => Category.unknown);
  }

  /// Transactions has payment or not
  bool get hasPayment => editing.paymentId != Payment.noneUuid;

  /// Show [T] item selection dialog
  Future<T?> showSelectDialog<T>(BuildContext context, String title, List<T> list) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return SelectDialog<T>(
          title: title,
          list: list,
        );
      },
    );
  }

  /// Show [Category] item selection dialog
  Future<Category?> showCategorySelectDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return CategorySelectDialog(
          selectedType: editing.type,
          showIncluded: editing.isIncluded,
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
  Future<bool> onNegativeButtonPressed() async {
    if (!isEdit) {
      return true;
    }
    return await provider.deleteTransaction(ref, editing);
  }

  /// Triggers on confirm button pressed
  Future<bool> onConfirmButtonPressed() async {
    if (isEdit) {
      return await provider.updateTransaction(ref, editing);
    }
    return await provider.createTransaction(ref, editing);
  }

  /// Set [editing.paidDate]
  void setPaidDate(DateTime date) {
    setState(() {
      editing.paidDate = date;
      setCalculatedDate();
    });
  }

  /// Set [editing.calculatedDate]
  ///
  /// If [date] is not `null`, set [editing.calculatedDate] to [date]. And
  /// [date] is `null` and [editing.calculatedDate] is equal to
  /// [Transaction.defaultCalculatedDate], set it from [editing.paidDate].
  ///
  /// Make [override] `true` to override [editing.calculatedDate] whether its value.
  void setCalculatedDate([DateTime? date]) {
    setState(() {
      if (date != null) {
        editing.calculatedDate = date;
        return;
      }
      final payment = selectedPayment;
      editing.calculatedDate = payment.getCalculatedDate(editing.paidDate);
    });
  }

  /// Set [editing.accountId] and [editing.currency]
  void setAccount(Account account) {
    setState(() {
      editing.setAccount(account);
    });
  }

  /// Set [editing.paymentId], [editing.altCurrency], [editing.altAmount] and
  /// [editing.calculatedDate].
  void setPayment(Payment payment) {
    setState(() {
      editing.setPayment(payment);
      setCalculatedDate();
    });
  }

  /// Set [editing.minusCategory] and [editing.type]
  void setCategory(Category category) {
    editing.categoryId = category.uuid;
    editing.type = category.type;
    editing.isIncluded = category.isIncluded;
    if (editing.type != TransactionType.expense) {
      onNoPaymentCheckboxChanged(true);
    }
  }

  /// Triggers on category card tapped
  void onCategoryCardTapped() async {
    final category = await showCategorySelectDialog(context);
    if (category != null) {
      setState(() {
        setCategory(category);
      });
    }
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
    final currency = provider.getCurrency(ref, editing.altCurrencyId);
    setState(() {
      if (Transaction.getAmountRegex(currency).hasMatch(value)) {
        if (value != "") {
          editing.altAmount = Decimal.parse(value);
        }
      }
    });
  }

  /// Triggers on amount changed
  void onAmountChanged(String value) {
    final currency = provider.getCurrency(ref, editing.currencyId);
    setState(() {
      if (Transaction.getAmountRegex(currency).hasMatch(value)) {
        if (value != "") {
          editing.amount = Decimal.parse(value);
        }
      }
    });
  }

  /// Triggers on description changed
  void onDescriptionChanged(String desc) {
    setState(() {
      editing.descriptions = desc;
    });
  }

  /// Triggers on cash checkboxes value changed
  void onIncludedValueChanged(bool value) {
    setState(() {
      editing.isIncluded = value;
    });
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
    setState(() {
      editing.utilityDays = range.duration.inDays + 1;
      utilityDaysController.text = editing.utilityDays.toString();
    });
  }

  /// Triggers on utility days value changed
  void onUtilityDaysValueChanged(String value) {
    setState(() {
      if (value != "") {
        editing.utilityDays = int.parse(value);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    editing = widget.base ?? Transaction.init();
    descriptionController.text = editing.descriptions;
    amountController.text = editing.amount.toString();
    altAmountController.text = (editing.altAmount ?? Decimal.zero).toString();
    utilityDaysController.text = editing.utilityDays.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.account != null) setAccount(widget.account!);
      if (widget.payment != null) setPayment(widget.payment!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final category = selectedCategory;
    final account = selectedAccount;
    final payment = selectedPayment;
    final bool useAlt = (payment != Payment.none) &&
        (account != Account.unknown) &&
        (editing.altCurrencyId != null) &&
        (editing.altCurrencyId != editing.currencyId);
    final currency = provider.getCurrency(ref, editing.currencyId);
    final altCurrency = provider.getCurrency(ref, editing.altCurrencyId);
    return Modal(
      ready: ready,
      title: LocaleKeys.object_action.tr(namedArgs: {
        "object": LocaleKeys.transaction.plural(1),
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
              DateButton(
                date: editing.paidDate,
                onChanged: setPaidDate,
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
                DateButton(
                  date: editing.calculatedDate,
                  onChanged: setCalculatedDate,
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
            onTap: onCategoryCardTapped,
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
            onTap: () => onAccountCardTapped(ref.watch(_filteredAccounts)),
          ),
          const SizedBox(height: 8,),
          // Payment
          Visibility(
            visible: editing.type == TransactionType.expense,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      LocaleKeys.payment.plural(1),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onNoPaymentCheckboxChanged(hasPayment),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Checkbox(
                              value: !hasPayment,
                              tristate: false,
                              onChanged: null,
                            ),
                            Text(
                              LocaleKeys.noPayment.plural(1),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Visibility(
                  visible: hasPayment,
                  child: PaymentCard(
                    data: payment,
                    unknownMessage: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
                      "object": LocaleKeys.payment.plural(1),
                    }),
                    onTap: () => onPaymentCardTapped(ref.watch(_filteredPayments)),
                  ),
                )
              ],
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
              keyboardType: TextInputType.numberWithOptions(
                decimal: (altCurrency == Currency.unknown) || (altCurrency.decimalPoint > 0),
              ),
              decoration: InputDecoration(
                labelText: LocaleKeys.paidAmount.tr(),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(4),
                  child: CurrencyIcon(altCurrency),
                ),
                errorText: Transaction.getAmountRegex(altCurrency).hasMatch(altAmountController.text)
                    ? null
                    : LocaleKeys.msgInvalidInput,
              ),
              inputFormatters: [
                FilteringTextInputFormatter(RegExp(r"[\d.]"), allow: true),
              ],
              onChanged: onAltAmountChanged,
            ),
          ),
          const SizedBox(height: 8,),
          // Amount
          TextField(
            controller: amountController,
            keyboardType: TextInputType.numberWithOptions(
              decimal: currency.decimalPoint > 0,
            ),
            decoration: InputDecoration(
              labelText: useAlt ? LocaleKeys.withdrawAmount.tr() : LocaleKeys.paidAmount.tr(),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(4),
                child: CurrencyIcon(currency),
              ),
              errorText: Transaction.getAmountRegex(currency).hasMatch(amountController.text)
                  ? null
                  : LocaleKeys.msgInvalidInput.tr(),
            ),
            inputFormatters: [
              FilteringTextInputFormatter(RegExp(r"[\d.]"), allow: true),
            ],
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
            maxLines: null,
            maxLength: BaseModel.maxTextLength,
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
                  keyboardType: TextInputType.number,
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
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onIncludedValueChanged(!editing.isIncluded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Checkbox(
                      value: editing.isIncluded,
                      onChanged: null,
                    ),
                    Text(
                      LocaleKeys.included.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}