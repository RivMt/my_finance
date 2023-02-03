import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/fragment/account_edit_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class AccountsFragment extends ConsumerStatefulWidget {
  const AccountsFragment({
    super.key,
    this.onItemTap,
    this.selected,
  });

  final Function(Account)? onItemTap;

  final Account? selected;

  @override
  _AccountsFragmentState createState() => _AccountsFragmentState();
}

class _AccountsFragmentState extends ConsumerState<AccountsFragment> {

  /// Request all accounts ordered by icon
  void request() {
    ref.read(FinanceProvider.accounts.notifier).request(
      {},
      ApiClient().buildOptions(
        sortOrderType: SortOrderType.asc,
        sortOrderAttribute: Account.keyIcon,
      ),
    );
  }

  /// Show account editing modal
  void showAccountEditingModal(BuildContext context, [Account? account]) {
    Account? editing = account;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        )
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width / InterfaceConstructor.panelNumber(context),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: AccountEditFragment(
            base: editing,
            onModified: (account) => editing = account,
          ),
        );
      }
    );
  }

  /// Triggers on account add button pressed
  void onAccountAddButtonPressed(BuildContext context) {
    showAccountEditingModal(context);
  }

  @override
  void initState() {
    super.initState();
    request();
  }

  @override
  void didUpdateWidget(AccountsFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(FinanceProvider.accounts);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Head
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.totalBalance.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: Currency.values.length,
                  itemBuilder: (context, index) {
                    final currency = Currency.values[index];
                    final sum = accounts.fold<Decimal>(Decimal.zero, (total, account) {
                      if (account.currency == currency) {
                        return total + account.balance;
                      }
                      return total;
                    });
                    if (sum == Decimal.zero) {
                      return const SizedBox();
                    }
                    return Text(
                      currency.format(sum),
                      style: Theme.of(context).textTheme.displayLarge,
                    );
                  },
                ),
              ],
            ),
          ),
          // List
          ListView.builder(
            shrinkWrap: true,
            itemCount: AccountIcon.values.length,
            itemBuilder: (context, index) {
              final icon = AccountIcon.values[index];
              final sublist = accounts.where((element) => (element.icon == icon)).toList(growable: false);
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
                    onTap: () {
                      if (widget.onItemTap == null) {
                        return;
                      }
                      widget.onItemTap!(account);
                    },
                  );
                },
              );
            },
          ),
          // Add
          ListTailButton(
            icon: Icons.add,
            title: LocaleKeys.add.tr(),
            onTap: () => onAccountAddButtonPressed(context),
          ),
        ],
      ),
    );
  }
}