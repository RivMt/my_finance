import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/account_edit_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

final _accounts = StateNotifierProvider<ModelsState<Account>, List<Account>>((ref) {
  return ModelsState<Account>(ref);
});

class AccountsFragment extends ConsumerStatefulWidget {
  const AccountsFragment({
    super.key,
    this.selected,
    this.conditions,
    this.hideHeader = false,
    this.hideCreateButton = false,
    this.onItemTap,
    this.onEditFinish,
  });

  final Function(Account)? onItemTap;

  final Function(Account)? onEditFinish;

  final Account? selected;

  final bool hideHeader;

  final bool hideCreateButton;

  final List<Map<String, dynamic>>? conditions;

  @override
  ConsumerState createState() => _AccountsFragmentState();
}

class _AccountsFragmentState extends ConsumerState<AccountsFragment> {

  /// Request all accounts ordered by icon
  void request() {
    ref.read(_accounts.notifier).request(
      widget.conditions ?? [{
        ModelKeys.keyDeleted: false,
        ModelKeys.keyPriority: {
          "min": 0,
        },
      }],
      ApiClient.buildOptions(
        sorts: [
          const Sort(ModelKeys.keyIcon, SortType.asc),
          const Sort(ModelKeys.keyLastUsed, SortType.desc),
        ],
      ),
    );
  }

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
            AccountEditFragment(
              base: editing,
              onFinish: (account) {
                Navigator.pop(context, account);
              },
            ),
          ],
        );
      },
    ).then((account) {
      request();
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
    request();
  }

  @override
  void didUpdateWidget(AccountsFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(_accounts);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Head
          Visibility(
            visible: !widget.hideHeader,
            child: GroupCard(
              title: LocaleKeys.totalBalance.tr(),
              count: Currency.values.length,
              build: (context, index) {
                final currency = Currency.values[index];
                bool exist = false;
                final sum = accounts.fold<Decimal>(Decimal.zero, (total, account) {
                  if (account.currency == currency) {
                    exist = true;
                    return total + account.balance;
                  }
                  return total;
                });
                if (!exist) {
                  return const SizedBox();
                }
                return CurrencyCard(
                  data: currency,
                  amount: sum,
                );
              },
            ),
          ),
          // List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AccountSymbol.values.length,
            itemBuilder: (context, index) {
              final icon = AccountSymbol.values[index];
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
                    onLongPress: () {
                      showAccountEditingModal(context, account);
                    },
                  );
                },
              );
            },
          ),
          // Add
          Visibility(
            visible: !widget.hideCreateButton,
            child: ListTailButton(
              icon: Icons.add,
              title: LocaleKeys.add.tr(),
              onTap: () => onAccountAddButtonPressed(context),
            ),
          ),
        ],
      ),
    );
  }
}