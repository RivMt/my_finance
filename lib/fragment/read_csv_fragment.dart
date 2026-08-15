import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/dialog/category_select_dialog.dart';
import 'package:my_finance/dialog/select_dialog.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

const String _tag = "ReadCsvFragment";

final _accounts = StateNotifierProvider<ModelsStateNotifier<Account>, List<Account>>((ref) {
  return ModelsStateNotifier<Account>();
});

final _payments = StateNotifierProvider<ModelsStateNotifier<Payment>, List<Payment>>((ref) {
  return ModelsStateNotifier<Payment>();
});

final _categories = StateNotifierProvider<ModelsStateNotifier<Category>, List<Category>>((ref) {
  return ModelsStateNotifier<Category>();
});

/// Receives transactions generated from the current CSV mapping.
typedef OnGeneration = void Function(BuildContext context, List<Transaction> list);

/// Maps CSV columns and rows to finance transactions.
class ReadCsvFragment extends ConsumerStatefulWidget {

  /// Called whenever a transaction preview is generated.
  final Function(List<Transaction>)? onGenerated;

  /// Receives the current generated transactions during a build.
  final OnGeneration? generate;

  const ReadCsvFragment({
    super.key,
    this.onGenerated,
    this.generate,
  });

  @override
  ConsumerState createState() => _ReadCsvFragmentState();
}

class _ReadCsvFragmentState extends ConsumerState<ReadCsvFragment> {

  /// Maximum number of rows in the inline preview.
  final int testNumber = 5;

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController dateFormatController = TextEditingController();

  /// Name of the selected CSV file.
  String? filename;

  /// Parsed CSV rows, including the header row.
  List<List<dynamic>> csv = [];

  /// Header cells from the first CSV row.
  List<dynamic> get headers {
    if (csv.isNotEmpty) {
      return csv[0];
    }
    return [];
  }

  /// Account assigned to generated transactions.
  Account account = Account.unknown;

  /// Payment assigned to generated transactions.
  Payment payment = Payment.unknown;

  /// Category assigned to negative CSV amounts.
  Category minusCategory = Category.unknown;

  /// Category assigned to positive CSV amounts.
  Category plusCategory = Category.unknown;

  /// Inclusive beginning of the imported date range.
  DateTime begin = DateUtils.dateOnly(DateTime.now().subtract(const Duration(days: 1)));

  /// Inclusive end of the imported date range.
  DateTime end = DateUtils.dateOnly(DateTime.now());

  /// Index of the CSV date column.
  int columnDate = 0;

  /// Index of the CSV amount column.
  int columnAmount = 1;

  /// Opens and parses a CSV file.
  void openCsv() async {
    PlatformFile? file = await FilePicker.pickFile();
    filename = null;
    if (file != null) {
      const converter = CsvDecoder();
      filename = file.name;
      final raw = await file.readAsBytes();
      csv = converter.convert(utf8.decode(raw));
      setState(() {});
    }
  }

  /// Generates transactions with an optional preview limit of [number].
  List<Transaction> generate([int? number]) {
    if (account == Account.unknown
        || payment == Payment.unknown
        || minusCategory == Category.unknown
        || payment.currencyId != account.currencyId
    ) {
      return [];
    }
    final int limit = number ?? csv.length;
    final List<Transaction> list = [];
    for(List<dynamic> row in csv) {
      if (list.length > limit) {
        break;
      }
      final item = Transaction();
      late DateTime date;
      final dateFormat = dateFormatController.text;
      final dateValue = row[columnDate];
      try {
        if (dateFormat.isNotEmpty) {
          final formatter = DateFormat(dateFormat);
          date = formatter.parse(dateValue);
        } else {
          date = DateTime.parse(dateValue);
        }
      } on FormatException {
        Log.e(_tag, "Unable to parse date: `$dateValue` by format `$dateFormat`");
        // TODO: Show error on DateFormat input field
        continue;
      }
      item.paidDate = date;
      if (begin.compareTo(item.paidDate) > 0 || end.compareTo(item.paidDate) < 0) {
        continue;
      }
      item.setAccount(account);
      item.currencyId = account.currencyId;
      item.setPayment(payment);
      item.calculatedDate = payment.getCalculatedDate(item.paidDate);
      try {
        item.amount = parseAmount(row[columnAmount]);
      } on FormatException {
        Log.e(_tag, "Unable to parse amount: `${row[columnAmount]}` as BigInt");
        continue;
      }
      if (item.amount < Decimal.zero) {
        item.categoryId = minusCategory.uuid;
        item.type = minusCategory.type;
        item.isIncluded = minusCategory.isIncluded;
        item.amount *= Decimal.fromInt(-1);
      } else {
        item.categoryId = plusCategory.uuid;
        item.type = plusCategory.type;
        item.isIncluded = plusCategory.isIncluded;
      }
      item.descriptions = parseDescription(descriptionController.text, row);
      list.add(item);
    }
    if (widget.onGenerated != null) {
      widget.onGenerated!(list);
    }
    return list;
  }

  /// Parses a CSV amount using the import sign convention.
  Decimal parseAmount(String literal) {
    if (literal.contains(RegExp("[\\-+]"))) {
      return Decimal.parse(literal.replaceAll(RegExp("[^0-9]"), ""));
    } else {
      return Decimal.parse("-${literal.replaceAll(RegExp("[^0-9]"), "")}");
    }
  }

  /// Expands header placeholders in a description template.
  String parseDescription(String function, List<dynamic> row) {
    final Map<String, int> map = {};
    final RegExp regex = RegExp(r"\$\{[^${}]+\}");
    final finds = regex.allMatches(function);
    for(RegExpMatch item in finds) {
      if (item.group(0) != null) {
        final String key = item.group(0)!;
        final int value = headers.indexWhere((element) => (element.toString() == key.replaceAll(RegExp(r"[${}]"), "")));
        if (value >= 0) {
          map[key] = value;
        }
      }
    }
    for(String pattern in map.keys) {
      if (map[pattern] != null) {
        function = function.replaceAll(pattern, row[map[pattern]!].toString());
      }
    }
    return function;
  }

  /// Shows a selection dialog for [list].
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

  /// Shows the category selection dialog.
  Future<Category?> showCategorySelectDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return CategorySelectDialog(
          onTap: (item) => Navigator.pop(context, item),
        );
      },
    );
  }

  /// Shows a date picker initialized with [base].
  Future<DateTime> showDatePickDialog(BuildContext context, DateTime base) async {
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.fromMillisecondsSinceEpoch(0),
      lastDate: Model.maxDate,
    );
    return result ?? base;
  }

  /// Selects the account for generated transactions.
  void setAccount(Account account) {
    setState(() {
      this.account = account;
    });
  }

  /// Selects the payment for generated transactions.
  void setPayment(Payment payment) {
    this.payment = payment;
  }

  /// Selects the category for negative CSV amounts.
  void setMinusCategory(Category category) => minusCategory = category;

  /// Selects the category for positive CSV amounts.
  void setPlusCategory(Category category) => plusCategory = category;

  /// Selects a positive or negative amount category.
  void onCategoryCardTapped(bool isPlus) async {
    final category = await showCategorySelectDialog(context);
    if (category != null) {
      if (isPlus) {
        setPlusCategory(category);
      } else {
        setMinusCategory(category);
      }
    }
    setState(() {});
  }

  /// Selects an account from [accounts].
  void onAccountCardTapped(List<Account> accounts) async {
    final account = await showSelectDialog(context, LocaleKeys.object_action.tr(namedArgs: {
      "object": LocaleKeys.account.plural(1),
      "action": LocaleKeys.select.tr(),
    }), accounts);
    if (account != null) {
      setAccount(account);
    }
    setPayment(payment);
    setState(() {});
  }

  /// Selects [Payment.none] when no payment handler is requested.
  void onNoPaymentCheckboxChanged(bool value) {
    setPayment(value ? Payment.none : Payment.unknown);
    setState(() {});
  }

  /// Selects a payment from [payments].
  void onPaymentCardTapped(List<Payment> payments) async {
    final payment = await showSelectDialog(context, LocaleKeys.object_action.tr(namedArgs: {
      "object": LocaleKeys.payment.plural(1),
      "action": LocaleKeys.select.tr(),
    }), payments);
    if (payment != null) {
      setPayment(payment);
    }
    setAccount(account);
    setState(() {});
  }

  /// Updates the beginning or end of the import date range.
  void onDateButtonPressed(BuildContext context, bool isBegin) async {
    final date = DateUtils.dateOnly(await showDatePickDialog(context, isBegin ? begin : end));
    setState(() {
      if (isBegin) {
        begin = date;
      } else {
        end = date;
      }
    });
  }

  /// Selects the CSV date column.
  void onDateColumnChanged(int index) {
    setState(() {
      columnDate = index;
    });
  }

  /// Selects the CSV amount column.
  void onAmountColumnChanged(int index) {
    setState(() {
      columnAmount = index;
    });
  }

  /// Refreshes the preview after the date format changes.
  void onDateFormatChanged(String text) {
    setState(() {});
  }

  /// Refreshes the preview after the description template changes.
  void onDescriptionChanged(String text) {
    setState(() {});
  }

  /// Fetches selectable accounts, payments, and categories.
  void request() async {
    // Active, visible accounts.
    await ref.read(_accounts.notifier).fetch({
      ModelKeys.keyDeleted: false,
      ModelKeys.keyPriority: {
        ApiQuery.keyQueryRangeBegin: 0,
      },
      ApiQuery.keySortField: [
        ModelKeys.keyLastUsed,
      ],
      ApiQuery.keySortOrder: [
        SortOrder.desc,
      ]
    });
    final account = this.account;
    setAccount(account);
    // Active, visible payments.
    await ref.read(_payments.notifier).fetch({
      ModelKeys.keyDeleted: false,
      ModelKeys.keyPriority: {
        ApiQuery.keyQueryRangeBegin: 0,
      },
      ApiQuery.keySortField: [
        ModelKeys.keyLastUsed,
      ],
      ApiQuery.keySortOrder: [
        SortOrder.desc,
      ]
    });
    final payment = this.payment;
    setPayment(payment);
    // Active categories.
    await ref.read(_categories.notifier).fetch({
      ModelKeys.keyDeleted: false,
      ApiQuery.keySortField: [
        ModelKeys.keyUuid,
      ],
      ApiQuery.keySortOrder: [
        SortOrder.asc,
      ]
    });
  }

  @override
  void initState() {
    super.initState();
    request();
  }

  @override
  void didUpdateWidget(ReadCsvFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    widget.generate?.call(context, generate());
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // CSV file.
              Text(
                LocaleKeys.file.tr(),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: openCsv,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                      ),
                      Text(filename ?? LocaleKeys.object_action.tr(namedArgs: {
                        "action": LocaleKeys.choose.tr(),
                        "object": LocaleKeys.file.tr(),
                      })),
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 8,),
          // Category mapping.
          Text(
            LocaleKeys.category.plural(1),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8,),
          // Negative amount category.
          Text(
            LocaleKeys.transactionTypeExpense.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          CategoryCard(
            category: minusCategory,
            unknownMessage: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
              "object": LocaleKeys.category.plural(1),
            }),
            onTap: () => onCategoryCardTapped(false),
          ),
          // Positive amount category.
          Text(
            LocaleKeys.transactionTypeIncome.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          CategoryCard(
            category: plusCategory,
            unknownMessage: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
              "object": LocaleKeys.category.plural(1),
            }),
            onTap: () => onCategoryCardTapped(true),
          ),
          const SizedBox(height: 8,),
          // Wallet mapping.
          Text(
            LocaleKeys.target.tr(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8,),
          // Account.
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
          // Payment.
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
                onTap: () => onNoPaymentCheckboxChanged(payment != Payment.none),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Checkbox(
                        value: payment == Payment.none,
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
          // Date mapping.
          Text(
            LocaleKeys.loadOptions.tr(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8,),
          // Import date range.
          Text(
            LocaleKeys.range.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8,),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.date_range_outlined,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8,),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onDateButtonPressed(context, true),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    DateFormat.yMd().format(begin),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(width: 16,),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onDateButtonPressed(context, false),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    DateFormat.yMd().format(end),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                LocaleKeys.columnDate.tr(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton(
                  borderRadius: BorderRadius.circular(8),
                  underline: null,
                  value: columnDate,
                  items: headers.indexed.map((e) {
                    return DropdownMenuItem(
                      value: e.$1,
                      child: Text(e.$2.toString()),
                    );
                  }).toList(growable: false),
                  onChanged: (index) => onDateColumnChanged(index ?? columnDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                LocaleKeys.columnAmount.tr(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton(
                  borderRadius: BorderRadius.circular(8),
                  value: columnAmount,
                  items: headers.indexed.map((e) {
                    return DropdownMenuItem(
                      value: e.$1,
                      child: Text(e.$2.toString()),
                    );
                  }).toList(growable: false),
                  onChanged: (index) => onAmountColumnChanged(index ?? columnAmount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8,),
          // Date format.
          Text(
            LocaleKeys.dateFormat.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4,),
          TextField(
            controller: dateFormatController,
            decoration: InputDecoration(
              labelText: LocaleKeys.dateFormat.tr(),
              prefixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            onChanged: onDateFormatChanged,
          ),
          const SizedBox(height: 8,),
          // Description template.
          Text(
            LocaleKeys.description.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4,),
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: LocaleKeys.description.tr(),
              prefixIcon: const Icon(Icons.functions_outlined),
            ),
            onChanged: onDescriptionChanged,
          ),
        ],
      ),
    );
  }
}
