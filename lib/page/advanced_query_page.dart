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
  ModelKeys.keyDescription,
  ModelKeys.keyIncluded,
];

/// Queries transactions by date and exports the results as CSV.
class AdvancedQueryPage extends ConsumerStatefulWidget {

  /// Legacy route name for the advanced query page.
  static const String route = "/csv";

  const AdvancedQueryPage({super.key});

  @override
  ConsumerState createState() => _AdvancedQueryPageState();
}

class _AdvancedQueryPageState extends ConsumerState<AdvancedQueryPage> {

  /// Inclusive beginning of the query range.
  DateTime minDate = DateTime(DateTime.now().year, 1, 1);

  /// End of the query range.
  DateTime maxDate = DateTime.now();

  /// Whether a query is in progress.
  bool progressing = false;

  /// Controls horizontal table scrolling.
  final ScrollController controller = ScrollController();

  /// Requests transactions in the selected date range.
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

  /// Builds a table row for [item].
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
        DataCell(Text(item.descriptions)),
        DataCell(Text(item.isIncluded.toString())),
      ],
    );
  }

  /// Exports the queried transactions through [DataFrame].
  void onDownloadButtonPressed() async {
    final accounts = ref.watch(provider.accounts);
    final payments = ref.watch(provider.payments);
    final categories = ref.watch(provider.categories);
    // Convert model fields to localized CSV values.
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
        ModelKeys.keyCategoryName: (item) {
          assert(item is Transaction);
          final category = categories.firstWhere((element) {
            return element.uuid == item.categoryId;
          }, orElse: () => Category.unknown);
          return category.name;
        },
        ModelKeys.keyAccountName: (item) {
          assert(item is Transaction);
          final account = accounts.firstWhere((element) {
            return element.uuid == item.accountId;
          }, orElse: () => Account.unknown);
          return account.name;
        },
        ModelKeys.keyPaymentName: (item) {
          assert(item is Transaction);
          final payment = payments.firstWhere((element) {
            return element.uuid == item.paymentId;
          }, orElse: () => Payment.unknown);
          return payment.name;
        },
      }
    );
    String raw = df.toCsv(
      separator: ",",
      newLine: "\r\n",
      escape: '"',
    );
    // Save the CSV to the selected path.
    try {
      final file = File(path);
      file.writeAsString(raw);
    } on Exception catch(e, s) {
      Log.e(_tag, "Exception: $e on $s");
    }
  }

  /// Updates the beginning of the query range.
  void onMinDateChanged(DateTime date) async {
    setState(() {
      minDate = date;
    });
  }

  /// Updates the end of the query range.
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
