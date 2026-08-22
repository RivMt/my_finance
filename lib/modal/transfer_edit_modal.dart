import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/dialog/select_dialog.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/model/transfer.dart';

final _transferAccounts = Provider<List<Account>>((ref) {
  final accounts = ref
      .watch(provider.accounts)
      .where((account) => !account.deleted)
      .toList();
  accounts.sort((first, second) => first.priority.compareTo(second.priority));
  return accounts;
});

/// Creates a transfer between two accounts.
class TransferEditModal extends ConsumerStatefulWidget {
  const TransferEditModal({
    super.key,
    this.accountFrom,
    this.accountTo,
  });

  /// Source account selected before opening the modal.
  final Account? accountFrom;

  /// Destination account selected before opening the modal.
  final Account? accountTo;

  @override
  ConsumerState createState() => _TransferEditModalState();
}

class _TransferEditModalState extends ConsumerState<TransferEditModal> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController altAmountController = TextEditingController();

  Transfer editing = Transfer.init();

  bool get ready =>
      editing.isValid &&
      amountController.text == editing.amount.toString() &&
      altAmountController.text == editing.altAmount.toString() &&
      descriptionController.text == editing.descriptions;

  Account get selectedAccountFrom => ref.watch(_transferAccounts).firstWhere(
        (account) => account.uuid == editing.accountId,
        orElse: () => Account.unknown,
      );

  Account get selectedAccountTo => ref.watch(_transferAccounts).firstWhere(
        (account) => account.uuid == editing.accountTo,
        orElse: () => Account.unknown,
      );

  Future<Account?> showAccountSelectDialog(
    List<Account> accounts,
    String accountLabel,
  ) {
    return showDialog<Account>(
      context: context,
      builder: (context) => SelectDialog<Account>(
        title: LocaleKeys.object_action.tr(namedArgs: {
          "object": accountLabel,
          "action": LocaleKeys.select.tr(),
        }),
        list: accounts,
      ),
    );
  }

  Future<void> onAccountFromCardTapped(List<Account> accounts) async {
    final accountFrom = await showAccountSelectDialog(
      accounts,
      LocaleKeys.accountTransferFrom.tr(),
    );
    if (accountFrom == null) return;
    setState(() {
      editing.accountId = accountFrom.uuid;
      editing.currencyId = accountFrom.currencyId;
      _synchronizeEqualCurrencyAmounts();
    });
  }

  Future<void> onAccountToCardTapped(List<Account> accounts) async {
    final accountTo = await showAccountSelectDialog(
      accounts,
      LocaleKeys.accountTransferTo.tr(),
    );
    if (accountTo == null) return;
    setState(() {
      editing.accountTo = accountTo.uuid;
      editing.altCurrencyId = accountTo.currencyId;
      _synchronizeEqualCurrencyAmounts();
    });
  }

  void _synchronizeEqualCurrencyAmounts() {
    if (!editing.useAlt) {
      editing.altAmount = editing.amount;
      altAmountController.text = amountController.text;
    }
  }

  void onAmountChanged(String value) {
    final currency = provider.getCurrency(ref, editing.currencyId);
    setState(() {
      if (value.isNotEmpty &&
          Transaction.getAmountRegex(currency).hasMatch(value)) {
        editing.amount = Decimal.parse(value);
        if (!editing.useAlt) {
          editing.altAmount = editing.amount;
          altAmountController.text = value;
        }
      }
    });
  }

  void onAltAmountChanged(String value) {
    final currency = provider.getCurrency(ref, editing.altCurrencyId);
    setState(() {
      if (value.isNotEmpty &&
          Transaction.getAmountRegex(currency).hasMatch(value)) {
        editing.altAmount = Decimal.parse(value);
      }
    });
  }

  void onDescriptionChanged(String value) {
    setState(() => editing.descriptions = value);
  }

  void setPaidDate(DateTime date) {
    setState(() {
      editing.paidDate = date;
      editing.calculatedDate = date;
    });
  }

  Future<bool> onConfirmButtonPressed() async {
    // TODO: Add custom provider pattern
    final response = await ApiClient().request(
      method: HttpMethod.post,
      endpoint: Transfer.endpoint,
      body: editing.map,
    );
    if (response.result != ApiResponseResult.success) return false;
    await provider.appendTransactions(ref, {});
    await provider.appendAccounts(ref);
    return true;
  }

  Future<bool> onNegativeButtonPressed() async => true;

  @override
  void initState() {
    super.initState();
    descriptionController.text = editing.descriptions;
    amountController.text = editing.amount.toString();
    altAmountController.text = editing.altAmount.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        if (widget.accountFrom != null) {
          editing.accountId = widget.accountFrom!.uuid;
          editing.currencyId = widget.accountFrom!.currencyId;
        }
        if (widget.accountTo != null) {
          editing.accountTo = widget.accountTo!.uuid;
          editing.altCurrencyId = widget.accountTo!.currencyId;
        }
        _synchronizeEqualCurrencyAmounts();
      });
    });
  }

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    altAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountFrom = selectedAccountFrom;
    final accountTo = selectedAccountTo;
    final currency = provider.getCurrency(ref, editing.currencyId);
    final altCurrency = provider.getCurrency(ref, editing.altCurrencyId);
    final accounts = ref.watch(_transferAccounts);

    return Modal(
      ready: ready,
      title: LocaleKeys.object_action.tr(namedArgs: {
        "object": LocaleKeys.transfer.tr(),
        "action": LocaleKeys.add.tr(),
      }),
      positiveButtonTitle: LocaleKeys.confirm.tr(),
      negativeButtonTitle: LocaleKeys.cancel.tr(),
      onPositiveButtonPressed: onConfirmButtonPressed,
      onNegativeButtonPressed: onNegativeButtonPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocaleKeys.date.tr(),
              style: Theme.of(context).textTheme.labelSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(LocaleKeys.transactionDate.tr(),
                  style: Theme.of(context).textTheme.labelMedium),
              DateButton(date: editing.paidDate, onChanged: setPaidDate),
            ],
          ),
          const SizedBox(height: 8),
          Text(LocaleKeys.accountTransferFrom.tr(),
              style: Theme.of(context).textTheme.labelSmall),
          AccountCard(
            data: accountFrom,
            showBalance: false,
            unknownMessage: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
              "object": LocaleKeys.accountTransferFrom.tr(),
            }),
            onTap: () => onAccountFromCardTapped(accounts),
          ),
          const SizedBox(height: 8),
          Text(LocaleKeys.accountTransferTo.tr(),
              style: Theme.of(context).textTheme.labelSmall),
          AccountCard(
            data: accountTo,
            showBalance: false,
            unknownMessage: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
              "object": LocaleKeys.accountTransferTo.tr(),
            }),
            onTap: () => onAccountToCardTapped(accounts),
          ),
          const SizedBox(height: 8),
          Text(LocaleKeys.basicInfo.tr(),
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.numberWithOptions(
              decimal:
                  currency == Currency.unknown || currency.decimalPoint > 0,
            ),
            decoration: InputDecoration(
              labelText: LocaleKeys.amountTransferFrom.tr(),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(4),
                child: CurrencyIcon(currency),
              ),
              errorText: Transaction.getAmountRegex(currency)
                      .hasMatch(amountController.text)
                  ? null
                  : LocaleKeys.msgInvalidInput.tr(),
            ),
            inputFormatters: [
              FilteringTextInputFormatter(RegExp(r"[\d.]"), allow: true),
            ],
            onChanged: onAmountChanged,
          ),
          if (editing.useAlt) ...[
            const SizedBox(height: 8),
            TextField(
              controller: altAmountController,
              keyboardType: TextInputType.numberWithOptions(
                decimal: altCurrency == Currency.unknown ||
                    altCurrency.decimalPoint > 0,
              ),
              decoration: InputDecoration(
                labelText: LocaleKeys.amountTransferTo.tr(),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(4),
                  child: CurrencyIcon(altCurrency),
                ),
                errorText: Transaction.getAmountRegex(altCurrency)
                        .hasMatch(altAmountController.text)
                    ? null
                    : LocaleKeys.msgInvalidInput.tr(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter(RegExp(r"[\d.]"), allow: true),
              ],
              onChanged: onAltAmountChanged,
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: LocaleKeys.description.tr(),
              prefixIcon: const Icon(Icons.notes),
            ),
            maxLines: null,
            maxLength: BaseModel.maxTextLength,
            onChanged: onDescriptionChanged,
          ),
        ],
      ),
    );
  }
}
