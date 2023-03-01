import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/priority_edit_fragment.dart';

final _account = StateNotifierProvider<ModelState<Account>, Account>((ref) {
  return ModelState<Account>(ref, Account.unknown);
});

class AccountDetailsFragment extends ConsumerStatefulWidget {
  const AccountDetailsFragment({
    super.key,
    required this.account,
  });

  final Account account;

  @override
  ConsumerState createState() => _AccountDetailsFragment();
}

class _AccountDetailsFragment extends ConsumerState<AccountDetailsFragment> {

  void request() async {
    ref.read(_account.notifier).request({
      ModelKeys.keyPid: widget.account.pid,
    });
  }

  /// Triggers on [PriorityEditFragment] pressed
  void onPressed(Account account, int priority) async {
    account.priority = priority;
    final result = await ApiClient().update<Account>([account.map]);
    if (result.result == ApiResultCode.success) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    request();
  }

  @override
  void didUpdateWidget(AccountDetailsFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(_account);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              WalletItemIcon(
                icon: account.icon.icon,
                foreground: account.foreground,
                background: account.background,
              ),
              const SizedBox(width: 8,),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.serialNumber,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      account.currency.format(account.balance),
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    Text(
                      account.descriptions,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PriorityEditFragment<Account>(
          data: account,
          onPressed: (priority) => onPressed(account, priority),
        ),
      ],
    );
  }
}