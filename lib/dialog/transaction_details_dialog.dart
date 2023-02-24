import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/page/accounts_page.dart';
import 'package:my_finance/page/categories_page.dart';
import 'package:my_finance/page/payments_page.dart';

final _category = StateNotifierProvider<ModelState<Category>, Category>((ref) {
  return ModelState(ref, Category.unknown);
});

final _account = StateNotifierProvider<ModelState<Account>, Account>((ref) {
  return ModelState(ref, Account.unknown);
});

final _payment = StateNotifierProvider<ModelState<Payment>, Payment>((ref) {
  return ModelState(ref, Payment.unknown);
});

class TransactionDetailsDialog extends ConsumerStatefulWidget {
  const TransactionDetailsDialog({
    super.key,
    required this.data,
  });

  final Transaction data;

  @override
  _TransactionDetailsDialogState createState() => _TransactionDetailsDialogState();
}

class _TransactionDetailsDialogState extends ConsumerState<TransactionDetailsDialog> {

  void openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => page,
    ));
  }

  void request() {
    ref.read(_category.notifier).request({
      FinanceModel.keyPid: widget.data.category,
    });
    ref.read(_account.notifier).request({
      FinanceModel.keyPid: widget.data.accountId,
    });
    ref.read(_payment.notifier).request({
      FinanceModel.keyPid: widget.data.paymentId,
    });
  }

  @override
  void initState() {
    super.initState();
    request();
  }

  @override
  Widget build(BuildContext context) {
    final category = ref.watch(_category);
    final account = ref.watch(_account);
    final payment = ref.watch(_payment);
    return AlertDialog(
      content: SizedBox(
        width: ScreenPlanner(context).dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Title
              ListTile(
                leading: Icon(widget.data.currency.icon),
                title: Text(
                  widget.data.amount.toString(),
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              // Descriptions
              Visibility(
                visible: widget.data.descriptions.isNotEmpty,
                child: ListTile(
                  leading: const Icon(Icons.notes_outlined),
                  title: Text(widget.data.descriptions),
                ),
              ),
              const Divider(),
              // Date
              Tooltip(
                message: LocaleKeys.paidDate.tr(),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(DateFormat.yMd().format(widget.data.paidDate)),
                ),
              ),
              Tooltip(
                message: LocaleKeys.createdDate.tr(),
                child: ListTile(
                  leading: const Icon(Icons.add_circle_outline_outlined),
                  title: Text(DateFormat.yMd().format(DateTime.fromMillisecondsSinceEpoch(widget.data.pid))),
                ),
              ),
              Tooltip(
                message: LocaleKeys.editedDate.tr(),
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(DateFormat.yMd().format(widget.data.lastUsed)),
                ),
              ),
              Tooltip(
                message: LocaleKeys.calculatedDate.tr(),
                child: Visibility(
                  visible: (widget.data.paidDate.year != widget.data.calculatedDate.year)
                      || (widget.data.paidDate.month == widget.data.calculatedDate.month)
                      || (widget.data.paidDate.day != widget.data.calculatedDate.day),
                  child: ListTile(
                    leading: const Icon(Icons.credit_score_outlined),
                    title: Text(DateFormat.yMd().format(widget.data.calculatedDate)),
                  ),
                ),
              ),
              const Divider(),
              // Relations
              CategoryCard(
                category: category,
                onTap: () => openPage(const CategoriesPage()),
              ),
              AccountCard(
                data: account,
                onTap: () => openPage(AccountsPage(
                  init: account,
                )),
              ),
              Visibility(
                visible: widget.data.paymentId != Payment.unknown.pid
                    && widget.data.paymentId != Payment.none.pid,
                child: PaymentCard(
                  data: payment,
                  onTap: () => openPage(PaymentsPage(
                    init: payment,
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}