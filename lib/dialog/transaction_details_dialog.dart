import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/navigator.dart';
import 'package:my_finance/page/categories_page.dart';

final _category = Provider.family<Category, Transaction>((ref, transaction) {
  final categories = [
    Category.transferTo,
    Category.transferFrom,
    ...ref.watch(provider.categories).where(
          (category) =>
              category.uuid != Category.transferTo.uuid &&
              category.uuid != Category.transferFrom.uuid,
        ),
  ];
  return categories.firstWhere(
    (category) =>
        category.uuid == transaction.categoryId &&
        category.type == transaction.type,
    orElse: () => Category.unknown,
  );
});

/// Displays amounts, related models, and dates for a [Transaction].
class TransactionDetailsDialog extends ConsumerStatefulWidget {
  const TransactionDetailsDialog({
    super.key,
    required this.data,
  });

  /// Transaction to display.
  final Transaction data;

  @override
  ConsumerState createState() => _TransactionDetailsDialogState();
}

class _TransactionDetailsDialogState
    extends ConsumerState<TransactionDetailsDialog> {
  /// Opens category management.
  void openCategoryPage() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CategoriesPage(),
        ));
  }

  /// Opens the detail page for [account].
  void openAccountPage(Account account) {
    final delegate = Router.of(context).routerDelegate;
    delegate
        .setNewRoutePath(FinanceRoutePath.accounts.extend(uuid: account.uuid));
  }

  /// Opens the detail page for [payment].
  void openPaymentPage(Payment payment) {
    final delegate = Router.of(context).routerDelegate;
    delegate
        .setNewRoutePath(FinanceRoutePath.payments.extend(uuid: payment.uuid));
  }

  @override
  Widget build(BuildContext context) {
    final category = ref.watch(_category(widget.data));
    final account = ref
        .watch(provider.accounts)
        .where((item) => item.uuid == widget.data.accountId)
        .first;
    final payments = ref
        .watch(provider.payments)
        .where((item) => item.uuid == widget.data.paymentId);
    final hasAlt = widget.data.hasAlt;
    final primaryCurrency =
        provider.getCurrency(ref, widget.data.primaryCurrencyId);
    final secondaryCurrency =
        provider.getCurrency(ref, widget.data.secondaryCurrencyId);
    return AlertDialog(
      content: SizedBox(
        width: ScreenPlanner(context).dialogWidth,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Primary amount.
              ListTile(
                leading: CurrencyIcon(primaryCurrency),
                title: Text(
                  widget.data.primaryAmount.toString(),
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              // Secondary amount for transactions with an alternate currency.
              Visibility(
                visible: hasAlt,
                child: ListTile(
                  leading: CurrencyIcon(secondaryCurrency),
                  title: Text(
                    widget.data.secondaryAmount.toString(),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ),
              // Category.
              Tooltip(
                message: category.descriptions,
                child: ListTile(
                  leading: Icon(category.icon.icon),
                  title: Text(category.name),
                  onTap: () => openCategoryPage(),
                ),
              ),
              // Transaction description.
              Visibility(
                visible: widget.data.descriptions.isNotEmpty,
                child: ListTile(
                  leading: const Icon(Icons.notes_outlined),
                  title: Text(widget.data.descriptions),
                ),
              ),
              // Transaction identifier.
              ListTile(
                leading: const Icon(Icons.numbers_outlined),
                title: SelectableText(widget.data.uuid),
              ),
              // Related account and payment.
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
                  visible: widget.data.paymentId != Payment.unknown.uuid &&
                      widget.data.paymentId != Payment.none.uuid,
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
              // Transaction dates.
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
                  title: Text(
                    DateFormat.yMd().format(widget.data.modifiedAt),
                  ),
                ),
              ),
              Tooltip(
                message: LocaleKeys.calculatedDate.tr(),
                child: Visibility(
                  visible: (widget.data.paidDate.year !=
                          widget.data.calculatedDate.year) ||
                      (widget.data.paidDate.month ==
                          widget.data.calculatedDate.month) ||
                      (widget.data.paidDate.day !=
                          widget.data.calculatedDate.day),
                  child: ListTile(
                    leading: const Icon(Icons.credit_score_outlined),
                    title: Text(
                        DateFormat.yMd().format(widget.data.calculatedDate)),
                  ),
                ),
              ),
              // Effective date range.
              Tooltip(
                message: LocaleKeys.utilityDays.tr(),
                child: ListTile(
                  leading: const Icon(Icons.date_range_outlined),
                  title: Text(LocaleKeys.nDay.plural(widget.data.utilityDays)),
                  subtitle:
                      Text(DateFormat.yMd().format(widget.data.utilityEnd)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
