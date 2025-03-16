import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/dialog/category_select_dialog.dart';
import 'package:my_finance/dialog/select_dialog.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

const String _tag = "ReadCsvFragment";

final _accounts = StateNotifierProvider<ModelsState<Account>, List<Account>>((ref) {
  return ModelsState<Account>(ref);
});

final _payments = StateNotifierProvider<ModelsState<Payment>, List<Payment>>((ref) {
  return ModelsState<Payment>(ref);
});

final _categories = StateNotifierProvider<ModelsState<Category>, List<Category>>((ref) {
  return ModelsState<Category>(ref);
});

typedef OnGeneration = void Function(BuildContext context, List<Transaction> list);

class ReadCsvFragment extends ConsumerStatefulWidget {

  final Function(List<Transaction>)? onGenerated;

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

  final int testNumber = 5;

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController dateFormatController = TextEditingController();

  String? filename;

  List<List<dynamic>> csv = [];

  List<dynamic> get headers {
    if (csv.isNotEmpty) {
      return csv[0];
    }
    return [];
  }

  Account account = Account.unknown;

  Payment payment = Payment.unknown;

  Category minusCategory = Category.unknown;

  Category plusCategory = Category.unknown;

  DateTime begin = DateUtils.dateOnly(DateTime.now().subtract(const Duration(days: 1)));

  DateTime end = DateUtils.dateOnly(DateTime.now());

  int columnDate = 0;

  int columnAmount = 1;

  void openCsv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    filename = null;
    if (result != null) {
      const converter = CsvToListConverter(
        eol: "\n",
      );
      filename = result.files.single.name;
      if (foundation.kIsWeb) {
        final raw = result.files.single.bytes;
        if (raw != null) {
          csv = converter.convert(utf8.decode(raw));
        }
      } else {
        csv = await File(result.files.single.path!).openRead().transform(utf8.decoder).transform(
            converter).toList();
      }
      setState(() {});
    }
  }

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
      try {
        late DateTime date;
        if (dateFormatController.text.isNotEmpty) {
          final formatter = DateFormat(dateFormatController.text);
          date = formatter.parse(row[columnDate]);
        } else {
          date = DateTime.parse(row[columnDate]);
        }
        item.paidDate = date;
        if (begin.compareTo(item.paidDate) > 0 || end.compareTo(item.paidDate) < 0) {
          continue;
        }
        item.setAccount(account);
        item.currencyId = account.currencyId;
        item.setPayment(payment);
        item.calculatedDate = payment.getCalculatedDate(item.paidDate);
        item.amount = parseAmount(row[columnAmount]);
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
      } on Exception {
        Log.e(_tag, "Failed to parse csv row: ${row.join(", ")}");
      }
    }
    if (widget.onGenerated != null) {
      widget.onGenerated!(list);
    }
    return list;
  }

  Decimal parseAmount(String literal) {
    if (literal.contains(RegExp("[\\-+]"))) {
      return Decimal.parse(literal.replaceAll(RegExp("[^0-9]"), ""));
    } else {
      return Decimal.parse("-${literal.replaceAll(RegExp("[^0-9]"), "")}");
    }
  }

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

  /// Set [editing.accountId] and [editing.currency]
  void setAccount(Account account) {
    setState(() {
      this.account = account;
    });
  }

  /// Set [editing.paymentId], [editing.altCurrency], [editing.altAmount] and
  /// [editing.calculatedDate].
  void setPayment(Payment payment) {
    this.payment = payment;
  }

  /// Set [editing.minusCategory] and [editing.type]
  void setMinusCategory(Category category) => minusCategory = category;

  void setPlusCategory(Category category) => plusCategory = category;

  /// Triggers on category card tapped
  void onCategoryCardTapped(List<Category> categories, bool isPlus) async {
    // Check categories has been loaded
    if (categories.isEmpty) {
      return;
    }
    final category = await showCategorySelectDialog(context, categories);
    if (category != null) {
      if (isPlus) {
        setPlusCategory(category);
      } else {
        setMinusCategory(category);
      }
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
    setPayment(payment);
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
    setAccount(account);
    setState(() {});
  }

  /// Triggers on paid date button pressed
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

  void onDateColumnChanged(int index) {
    setState(() {
      columnDate = index;
    });
  }

  void onAmountColumnChanged(int index) {
    setState(() {
      columnAmount = index;
    });
  }

  void onDateFormatChanged(String text) {
    setState(() {});
  }

  void onDescriptionChanged(String text) {
    setState(() {});
  }

  /// Request
  void request() async {
    // Account
    await ref.read(_accounts.notifier).request([{
      ModelKeys.keyDeleted: false,
      ModelKeys.keyPriority: {
        "min": 0,
      },
    }], ApiClient.buildOptions(
      sorts: [
        const Sort(ModelKeys.keyLastUsed, SortType.desc),
      ],
    ));
    final account = this.account;
    setAccount(account);
    // Payment
    await ref.read(_payments.notifier).request([{
      ModelKeys.keyDeleted: false,
      ModelKeys.keyPriority: {
        "min": 0,
      },
    }], ApiClient.buildOptions(
      sorts: [
        const Sort(ModelKeys.keyLastUsed, SortType.desc),
      ],
    ));
    final payment = this.payment;
    setPayment(payment);
    // Category
    await ref.read(_categories.notifier).request([{
      ModelKeys.keyDeleted: false,
    }], ApiClient.buildOptions(
      sorts: [
        const Sort(ModelKeys.keyPid, SortType.asc),
      ],
    ));
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
              // File
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
          // Category
          Text(
            LocaleKeys.category.plural(1),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8,),
          // Category (Expense)
          Text(
            LocaleKeys.transactionTypeExpense.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          CategoryCard(
            category: minusCategory,
            unknownMessage: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
              "object": LocaleKeys.category.plural(1),
            }),
            onTap: () => onCategoryCardTapped(ref.watch(_categories), false),
          ),
          // Category (Income)
          Text(
            LocaleKeys.transactionTypeIncome.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          CategoryCard(
            category: plusCategory,
            unknownMessage: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
              "object": LocaleKeys.category.plural(1),
            }),
            onTap: () => onCategoryCardTapped(ref.watch(_categories), true),
          ),
          const SizedBox(height: 8,),
          // Target
          Text(
            LocaleKeys.target.tr(),
            style: Theme.of(context).textTheme.labelMedium,
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
          // Date
          Text(
            LocaleKeys.loadOptions.tr(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8,),
          // Date range
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
          // DateFormat
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
          // Description
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