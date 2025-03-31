import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/modal/account_edit_modal.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class AccountsFragment extends ConsumerStatefulWidget {
  const AccountsFragment({
    super.key,
    required this.accounts,
    this.selected,
    this.hideHeader = false,
    this.hideCreateButton = false,
    this.onItemTap,
    this.onEditFinish,
  });

  final List<Account> accounts;

  final Function(Account)? onItemTap;

  final Function(Account)? onEditFinish;

  final Account? selected;

  final bool hideHeader;

  final bool hideCreateButton;

  @override
  ConsumerState createState() => _AccountsFragmentState();
}

class _AccountsFragmentState extends ConsumerState<AccountsFragment> {

  /// Show account editing modal
  void showAccountEditingModal(BuildContext context, [Account? account]) async {
    Account? editing = account;
    showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) {
        return Wrap(
          children: [
            AccountEditModal(
              base: editing,
              onFinish: (account) {
                Navigator.pop(context, account);
              },
            ),
          ],
        );
      },
    ).then((account) {
      provider.refreshAccounts(ref);
      if (widget.onEditFinish != null && account != null) {
        widget.onEditFinish!(account);
      }
    });
  }

  /// Triggers on account add button pressed
  void onAccountAddButtonPressed(BuildContext context) {
    showAccountEditingModal(context);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currencies = ref.watch(provider.currencies);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: MasonryGridView.count(
        itemCount: AccountSymbol.values.length + 2,
        crossAxisCount: ScreenPlanner(context).panelNumber,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        itemBuilder: (context, index) {
          // Header
          if (index == 0) {
            if (widget.hideHeader) {
              return const SizedBox();
            }
            return GroupCard(
              title: LocaleKeys.totalBalance.tr(),
              count: currencies.length,
              build: (context, index) {
                final currency = currencies[index];
                bool exist = false;
                final sum = widget.accounts.fold<Decimal>(Decimal.zero, (total, account) {
                  if (account.currencyId == currency.uuid) {
                    exist = true;
                    return total + account.balance;
                  }
                  return total;
                });
                if (!exist) {
                  return const SizedBox();
                }
                return CurrencyCard(
                  currency: currency,
                  amount: sum,
                );
              },
            );
          }
          // Tailing button
          if (index == AccountSymbol.values.length + 1) {
            return Visibility(
              visible: !widget.hideCreateButton,
              child: ListTailButton(
                icon: Icons.add,
                title: LocaleKeys.add.tr(),
                onTap: () => onAccountAddButtonPressed(context),
              ),
            );
          }
          // Accounts
          final icon = AccountSymbol.values[index-1];
          final sublist = widget.accounts.where((element) => (element.icon == icon)).toList(growable: false);
          // Hide when sublist is empty
          if (sublist.isEmpty) {
            return const SizedBox();
          }
          // Group
          return GroupCard(
            title: icon.key.tr(),
            count: sublist.length,
            build: (context, index) {
              final account = sublist[index];
              return AccountCard(
                data: account,
                selected: widget.selected == account,
                ignoreDeleted: true,
                onTap: () {
                  if (widget.onItemTap == null) {
                    return;
                  }
                  widget.onItemTap!(account);
                },
                onLongPress: () {
                  showAccountEditingModal(context, account);
                },
              );
            },
          );
        },
      )
    );
  }
}