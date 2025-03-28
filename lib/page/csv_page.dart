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

final _transactions = StateNotifierProvider<ModelsState<RawTransaction>, List<RawTransaction>>((ref) {
  return ModelsState<RawTransaction>(ref, "");
});

class CsvPage extends ConsumerStatefulWidget {

  static const String route = "/csv";

  const CsvPage({super.key});

  @override
  ConsumerState createState() => _CsvPageState();
}

class _CsvPageState extends ConsumerState<CsvPage> {

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
    ref.read(_transactions.notifier).request({
      ApiQuery.keyQueryRangeBegin: minDate.toIso8601String(),
      ApiQuery.keyQueryRangeEnd: maxDate.toIso8601String(),
    });
    setState(() {
      progressing = false;
    });
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
    final DataFrame<RawTransaction> df = DataFrame(
      columns: RawTransaction.columns,
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
  void didUpdateWidget(CsvPage oldWidget) {
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
                    columns: List.generate(RawTransaction.columns.length, (index) {
                      final String name = RawTransaction.columns[index];
                      return DataColumn(
                        label: Text(name),
                        tooltip: name,
                      );
                    }),
                    rows: List.generate(transactions.length, (index) {
                      final item = transactions[index];
                      final currency = provider.getCurrency(ref, item.currencyId);
                      final altCurrency = provider.getCurrency(ref, item.altCurrencyId);
                      return DataRow(
                        cells: [
                          DataCell(Text(item.uuid.toString())),
                          DataCell(Text(item.type.key.tr())),
                          DataCell(Text(item.categoryName)),
                          DataCell(Text(item.accountName)),
                          DataCell(Text(item.paymentName)),
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