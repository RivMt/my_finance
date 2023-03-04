import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

final _transactions = StateNotifierProvider<ModelsState<RawTransaction>, List<RawTransaction>>((ref) {
  return ModelsState<RawTransaction>(ref);
});

class CsvPage extends ConsumerStatefulWidget {
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

  void request() async {
    if (minDate.compareTo(maxDate) > 0) {
      return;
    }
    setState(() {
      progressing = true;
    });
    ref.read(_transactions.notifier).request([], {}, {
      "min": minDate.millisecondsSinceEpoch,
      "max": maxDate.millisecondsSinceEpoch,
    });
    setState(() {
      progressing = false;
    });
  }

  /// Triggers on [minDate] [DateButton] pressed
  void onMinDatePressed(BuildContext context) async {
    final result = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: Model.minDate,
      lastDate: Model.maxDate,
    );
    setState(() {
      minDate = result ?? minDate;
    });
  }

  /// Triggers on [maxDate] [DateButton] pressed
  void onMaxDatePressed(BuildContext context) async {
    final result = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: Model.minDate,
      lastDate: Model.maxDate,
    );
    setState(() {
      maxDate = result ?? maxDate;
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
        title: Text(''),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Visibility(
            visible: progressing,
            child: const LinearProgressIndicator(
              value: null,
            ),
          ),
        ),
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
                onTap: () => onMinDatePressed(context),
              ),
              const Text('~'),
              DateButton(
                date: maxDate,
                onTap: () => onMaxDatePressed(context),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
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
                    return DataRow(
                      cells: [
                        DataCell(Text(item.pid.toString())),
                        DataCell(Text(item.type.key.tr())),
                        DataCell(Text(item.categoryName)),
                        DataCell(Text(item.accountName)),
                        DataCell(Text(item.paymentName)),
                        DataCell(Text(item.currency.key.tr())),
                        DataCell(Text(item.amount.toString())),
                        DataCell(Text(item.altCurrency == null
                            ? ""
                            : item.altCurrency!.key.tr())
                        ),
                        DataCell(Text(item.altAmount == null
                            ? ""
                            : item.altAmount.toString())
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
        ],
      ),
    );
  }
}