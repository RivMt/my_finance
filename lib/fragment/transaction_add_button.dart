import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/modal/transaction_edit_modal.dart';

/// Opens a transaction modal with an optional account or payment preset.
class TransactionAddButton extends StatelessWidget {

  static const String _heroTag = "TransactionAddButton";

  const TransactionAddButton({
    super.key,
    this.account,
    this.payment,
  });

  /// Account selected before creating the transaction.
  final Account? account;

  /// Payment selected before creating the transaction.
  final Payment? payment;

  /// Opens the transaction creation modal.
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
