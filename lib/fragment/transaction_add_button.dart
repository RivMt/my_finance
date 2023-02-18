import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/transaction_edit_fragment.dart';

class TransactionAddButton extends StatelessWidget {
  const TransactionAddButton({
    super.key,
    this.onFinish,
  });

  final Function(Transaction?)? onFinish;

  void showTransactionCreateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) => TransactionEditFragment(
        onFinish: (item) => Navigator.pop(context, item),
      ),
    ).then((value) {
      if (onFinish != null) {
        onFinish!(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showTransactionCreateModal(context),
      child: const Icon(Icons.add),
    );
  }
}