import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/modal/transaction_edit_modal.dart';

class TransactionAddButton extends StatelessWidget {
  const TransactionAddButton({
    super.key,
    this.account,
    this.payment,
    this.onFinish,
  });

  /// Selected [Account]
  final Account? account;

  /// Selected [Payment]
  final Payment? payment;

  final Function(Transaction?)? onFinish;

  void showTransactionCreateModal(BuildContext context) {
    final Transaction data = Transaction.init();
    if (account != null && account != Account.unknown) {
      data.setAccount(account!);
    }
    if (payment != null && payment != Payment.unknown) {
      data.setPayment(payment!);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) => TransactionEditModal(
        base: data,
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