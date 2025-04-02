import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/page/account_details_page.dart';
import 'package:my_finance/page/categories_page.dart';
import 'package:my_finance/page/payment_details_page.dart';
import 'package:my_finance/local_provider.dart' as local_provider;

class TransactionDetailsDialog extends ConsumerStatefulWidget {
  const TransactionDetailsDialog({
    super.key,
    required this.data,
  });

  final Transaction data;

  @override
  ConsumerState createState() => _TransactionDetailsDialogState();
}

class _TransactionDetailsDialogState extends ConsumerState<TransactionDetailsDialog> {

  void openCategoryPage() {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => const CategoriesPage(),
    ));
  }

  void openAccountPage(Account account) {
    ref.read(local_provider.selectedAccount.notifier).set(account.uuid);
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => const AccountDetailsPage(),
    ));
  }

  void openPaymentPage(Payment payment) {
    ref.read(local_provider.selectedPayment.notifier).set(payment.uuid);
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => const PaymentDetailsPage(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final category = ref.watch(provider.categories).where((item) => item.uuid == widget.data.categoryId).first;
    final account = ref.watch(provider.accounts).where((item) => item.uuid == widget.data.accountId).first;
    final payments = ref.watch(provider.payments).where((item) => item.uuid == widget.data.paymentId);
    final hasAlt = widget.data.hasAlt;
    final primaryCurrency = provider.getCurrency(ref, hasAlt ? widget.data.altCurrencyId! : widget.data.currencyId);
    final secondaryCurrency = provider.getCurrency(ref, widget.data.currencyId);
    return AlertDialog(
      content: SizedBox(
        width: ScreenPlanner(context).dialogWidth,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Amount (Primary)
              ListTile(
                leading: CurrencyIcon(primaryCurrency),
                title: Text(
                  (hasAlt ? widget.data.altAmount : widget.data.amount).toString(),
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              // Amount (Secondary)
              Visibility(
                visible: hasAlt,
                child: ListTile(
                  leading: CurrencyIcon(secondaryCurrency),
                  title: Text(
                    widget.data.amount.toString(),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ),
              // Category
              Tooltip(
                message: category.descriptions,
                child: ListTile(
                  leading: Icon(category.icon.icon),
                  title: Text(category.name),
                  onTap: () => openCategoryPage(),
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
              // UUID
              ListTile(
                leading: const Icon(Icons.numbers_outlined),
                title: SelectableText(widget.data.uuid),
              ),
              // Details
              const Divider(),
              Tooltip(
                message: account.descriptions,
                child: ListTile(
                  leading: Icon(account.icon.icon),
                  title: Text(account.name),
                  subtitle: Text(account.serialNumber),
                  onTap: () => openAccountPage(account),
                ),
              ),
              if (payments.isNotEmpty)
                Visibility(
                  visible: widget.data.paymentId != Payment.unknown.uuid
                      && widget.data.paymentId != Payment.none.uuid,
                  child: Tooltip(
                    message: payments.first.descriptions,
                    child: ListTile(
                      leading: Icon(payments.first.icon.icon),
                      title: Text(payments.first.name),
                      subtitle: Text(payments.first.serialNumber),
                      onTap: () => openPaymentPage(payments.first),
                    ),
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
              // Utility
              Tooltip(
                message: LocaleKeys.utilityDays.tr(),
                child: ListTile(
                  leading: const Icon(Icons.date_range_outlined),
                  title: Text(LocaleKeys.nDay.plural(widget.data.utilityDays)),
                  subtitle: Text(DateFormat.yMd().format(widget.data.utilityEnd)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}