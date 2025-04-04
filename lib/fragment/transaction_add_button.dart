import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/modal/transaction_edit_modal.dart';

class TransactionAddButton extends StatelessWidget {

  static const String _heroTag = "TransactionAddButton";

  const TransactionAddButton({
    super.key,
    this.account,
    this.payment,
  });

  /// Selected [Account]
  final Account? account;

  /// Selected [Payment]
  final Payment? payment;

  void showTransactionCreateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) => TransactionEditModal(
        account: account,
        payment: payment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: _heroTag,
      onPressed: () => showTransactionCreateModal(context),
      child: const Icon(Icons.add),
    );
  }
}