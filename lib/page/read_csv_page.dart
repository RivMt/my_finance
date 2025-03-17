import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/read_csv_fragment.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

const String _tag = "ReadCsvPage";

class ReadCsvPage extends StatefulWidget {
  const ReadCsvPage({
    super.key,
  });

  @override
  State createState() => _ReadCsvPageState();
}

class _ReadCsvPageState extends State<ReadCsvPage> {

  List<Transaction> transactions = [];

  bool progressing = false;

  void showPreviewModel(BuildContext context) {
    setState(() {});
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: TransactionsFragment(
            items: transactions,
          ),
        );
      },
    );
  }

  void showToast(String message) {
    final snackBar = SnackBar(
      content: Text(message),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void create() async {
    setState(() {
      progressing = true;
    });
    bool failed = false;
    String message = "";
    final List<Transaction> list = [];
    for(final Transaction item in transactions) {
      if (!item.isValid) {
        failed = true;
        message = "ItemInvalid";
        break;
      }
      list.add(item);
    }
    if (!failed) {
      for (Transaction item in list) {
        final ApiResponse<Transaction> response = await ApiClient().create(item.map);
        Log.v(_tag, "Send CSV record (${item.uuid}): ${response.result.name}");
        if (response.result != ApiResultCode.success) {
          failed = true;
          message = "RequestFailed";
        }
      }
    }
    setState(() {
      progressing = false;
    });
    if (failed) {
      showToast(LocaleKeys.msgError.tr(args: [message]));
    } else {
      showToast(LocaleKeys.msgTaskComplete);
      setState(() {
        transactions = [];
      });
    }
  }

  void onSavePressed() => create();

  @override
  Widget build(BuildContext context) {
    final width = ScreenPlanner(context).panelWidth;
    final sideVisible = ScreenPlanner(context).isSidePanelVisible;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.readCsv.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () => onSavePressed(),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
            child: Visibility(
              visible: progressing,
              child: const LinearProgressIndicator(),
          ),
        ),
      ),
      body: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: width,
              child: ReadCsvFragment(
                generate: (context, list) => transactions = list,
              ),
            ),
            Visibility(
              visible: sideVisible,
              child: Container(
                padding: const EdgeInsets.all(16),
                width: width,
                child: TransactionsFragment(
                  items: transactions,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: sideVisible ? LocaleKeys.refresh.tr() : LocaleKeys.preview.tr(),
        onPressed: sideVisible ? () => setState(() {}) : () => showPreviewModel(context),
        child: Icon(sideVisible ? Icons.sync : Icons.visibility_outlined),
      ),
    );
  }
}