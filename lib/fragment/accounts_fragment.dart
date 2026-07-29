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

/// Groups accounts by [AccountSymbol] and displays their balances.
class AccountsFragment extends ConsumerWidget {
  const AccountsFragment({
    super.key,
    required this.accounts,
    this.selected,
    this.hideHeader = false,
    this.hideCreateButton = false,
    this.onItemTap,
  });

  /// Accounts to display.
  final List<Account> accounts;

  /// Called when an account is tapped.
  final Function(Account)? onItemTap;

  /// Account highlighted as selected.
  final Account? selected;

  /// Whether to hide the total-balance header.
  final bool hideHeader;

  /// Whether to hide the account creation button.
  final bool hideCreateButton;

  /// Shows the account creation or editing modal.
  void showAccountEditingModal(BuildContext context, [Account? account]) async {
    showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) {
        return Wrap(
          children: [
            AccountEditModal(account),
          ],
        );
      },
    );
  }

  /// Opens the account creation modal.
  void onAccountAddButtonPressed(BuildContext context) {
    showAccountEditingModal(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencies = ref.watch(provider.currencies);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: MasonryGridView.count(
        itemCount: AccountSymbol.values.length + 2,
        crossAxisCount: ScreenPlanner(context).panelNumber,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        itemBuilder: (context, index) {
          // Balances grouped by currency.
          if (index == 0) {
            if (hideHeader) {
              return const SizedBox();
            }
            return GroupCard(
              title: LocaleKeys.totalBalance.tr(),
              count: currencies.length,
              build: (context, index) {
                final currency = currencies[index];
                bool exist = false;
                final sum = accounts.fold<Decimal>(Decimal.zero, (total, account) {
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
          // Account creation button.
          if (index == AccountSymbol.values.length + 1) {
            return Visibility(
              visible: !hideCreateButton,
              child: ListTailButton(
                icon: Icons.add,
                title: LocaleKeys.add.tr(),
                onTap: () => onAccountAddButtonPressed(context),
              ),
            );
          }
          // Accounts for this symbol.
          final icon = AccountSymbol.values[index-1];
          final sublist = accounts.where((element) => (element.icon == icon)).toList(growable: false);
          // Omit empty symbol groups.
          if (sublist.isEmpty) {
            return const SizedBox();
          }
          // Symbol group.
          return GroupCard(
            title: icon.key.tr(),
            count: sublist.length,
            build: (context, index) {
              final account = sublist[index];
              return AccountCard(
                data: account,
                selected: selected == account,
                ignoreDeleted: true,
                onTap: () {
                  if (onItemTap == null) {
                    return;
                  }
                  onItemTap!(account);
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
