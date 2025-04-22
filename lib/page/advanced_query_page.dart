import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/generated/locale_keys.g.dart';

const String _tag = "CsvPage";

final _transactions = StateNotifierProvider<ModelsStateNotifier<Transaction>, List<Transaction>>((ref) {
  return ModelsStateNotifier<Transaction>();
});

final _columns = [
  ModelKeys.keyUuid,
  ModelKeys.keyType,
  ModelKeys.keyCategoryName,
  ModelKeys.keyAccountName,
  ModelKeys.keyPaymentName,
  ModelKeys.keyCurrencyId,
  ModelKeys.keyAmount,
  ModelKeys.keyAltCurrencyId,
  ModelKeys.keyAltAmount,
  ModelKeys.keyPaidDate,
  ModelKeys.keyCalculatedDate,
  ModelKeys.keyUtilityEnd,
  ModelKeys.keyDescription,
  ModelKeys.keyIncluded,
];

class AdvancedQueryPage extends ConsumerStatefulWidget {

  static const String route = "/csv";

  const AdvancedQueryPage({super.key});

  @override
  ConsumerState createState() => _AdvancedQueryPageState();
}

class _AdvancedQueryPageState extends ConsumerState<AdvancedQueryPage> {

  /// Beginning [DateTime] of condition
  DateTime minDate = DateTime(DateTime.now().year, 1, 1);

  /// End of [DateTime] of condition
  DateTime maxDate = DateTime.now();

  /// Value of request is progressing or not
  bool progressing = false;

  /// Horizontal scroll controller
  final ScrollController controller = ScrollController();

  /// Request [RawTransaction]s
  void request() async {
    if (minDate.compareTo(maxDate) > 0) {
      return;
    }
    setState(() {
      progressing = true;
    });
    ref.read(_transactions.notifier).fetch({
      ApiQuery.keyQueryRangeBegin: minDate.toIso8601String(),
      ApiQuery.keyQueryRangeEnd: maxDate.toIso8601String(),
    });
    setState(() {
      progressing = false;
    });
  }

  /// Generate data row
  DataRow getDataRow(Transaction item) {
    final accounts = ref.watch(provider.accounts);
    final payments = ref.watch(provider.payments);
    final categories = ref.watch(provider.categories);
    final account = accounts.firstWhere((element) => element.uuid == item.accountId, orElse: () => Account.unknown);
    final payment = payments.firstWhere((element) => element.uuid == item.paymentId, orElse: () => Payment.unknown);
    final category = categories.firstWhere((element) => element.uuid == item.categoryId, orElse: () => Category.unknown);
    final currency = provider.getCurrency(ref, item.currencyId);
    final altCurrency = provider.getCurrency(ref, item.altCurrencyId);
    return DataRow(
      cells: [
        DataCell(Text(item.uuid.toString())),
        DataCell(Text(item.type.key.tr())),
        DataCell(Text(category.name)),
        DataCell(Text(account.name)),
        DataCell(Text(payment.name)),
        DataCell(Text(item.currencyId)),
        DataCell(Text(currency.format(item.amount))),
        DataCell(Text(item.altCurrencyId == null
            ? ""
            : item.altCurrencyId!)
        ),
        DataCell(Text(item.altAmount == null || item.altCurrencyId == null
            ? ""
            : altCurrency.format(item.altAmount!))
        ),
        DataCell(Text(DateFormat.yMd().format(item.paidDate))),
        DataCell(Text(DateFormat.yMd().format(item.calculatedDate))),
        DataCell(Text(DateFormat.yMd().format(item.utilityEnd))),
        DataCell(Text(item.descriptions)),
        DataCell(Text(item.isIncluded.toString())),
      ],
    );
  }

  /// Triggers on download button pressed
  void onDownloadButtonPressed() async {
    String? path = await FilePicker.platform.saveFile(
      dialogTitle: LocaleKeys.msgExportCsv.tr(),
      fileName: 'data.csv',
      allowedExtensions: ['csv'],
    );
    if (path == null) {
      return;
    }
    // Create raw csv
    final DataFrame<Transaction> df = DataFrame(
      columns: _columns,
      data: ref.watch(_transactions),
      conversions: {
        ModelKeys.keyType: (type) {
          assert(type is int);
          return TransactionType.fromCode(type).key.tr();
        },
        ModelKeys.keyCurrencyId: (value) {
          assert(value is String);
          final currency = provider.getCurrency(ref, value);
          return currency.key.tr();
        },
        ModelKeys.keyAltCurrencyId: (alt) {
          assert(alt is String?);
          if (alt == null) {
            return "";
          }
          final currency = provider.getCurrency(ref, alt);
          return currency.key.tr();
        },
        ModelKeys.keyPaidDate: (date) {
          assert(date is int);
          return DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(date));
        },
        ModelKeys.keyCalculatedDate: (date) {
          assert(date is int);
          return DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(date));
        },
        ModelKeys.keyUtilityEnd: (date) {
          assert(date is int);
          return DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(date));
        },
      }
    );
    String raw = df.toCsv(
      separator: ",",
      newLine: "\r\n",
      escape: '"',
    );
    // Save
    try {
      final file = File(path);
      file.writeAsString(raw);
    } on Exception catch(e, s) {
      Log.e(_tag, "Exception: $e on $s");
    }
  }

  /// Triggers on [minDate] setting [DateButton] pressed
  void onMinDateChanged(DateTime date) async {
    setState(() {
      minDate = date;
    });
  }

  /// Triggers on [maxDate] setting [DateButton] pressed
  void onMaxDateChanged(DateTime date) async {
    setState(() {
      maxDate = date;
    });
  }

  @override
  void didUpdateWidget(AdvancedQueryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(_transactions);
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.advancedQuery.tr()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Visibility(
            visible: progressing,
            child: const LinearProgressIndicator(
              value: null,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: onDownloadButtonPressed,
          )
        ],
      ),
      body: Column(
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              ElevatedButton(
                onPressed: request,
                child: Text(LocaleKeys.confirm.tr()),
              ),
              DateButton(
                date: minDate,
                onChanged: onMinDateChanged,
              ),
              const Text('~'),
              DateButton(
                date: maxDate,
                onChanged: onMaxDateChanged,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Scrollbar(
                thumbVisibility: true,
                controller: controller,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: controller,
                  child: DataTable(
                    columns: List.generate(_columns.length, (index) {
                      final String name = _columns[index];
                      return DataColumn(
                        label: Text(name),
                        tooltip: name,
                      );
                    }),
                    rows: List.generate(transactions.length, (index) {
                      return getDataRow(transactions[index]);
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}