import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/priority_edit_fragment.dart';

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

  /// Triggers on [PriorityEditFragment] pressed
  void onPressed(Account account, int priority) async {
    account.priority = priority;
    final result = await ApiClient().update<Account>([account.map]);
    if (result.result == ApiResultCode.success) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
                icon: widget.account.icon.icon,
                foreground: widget.account.foreground,
                background: widget.account.background,
              ),
              const SizedBox(width: 8,),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.account.serialNumber,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      widget.account.currency.format(widget.account.balance),
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    Text(
                      widget.account.descriptions,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PriorityEditFragment<Account>(
          data: widget.account,
          onPressed: (priority) => onPressed(widget.account, priority),
        ),
      ],
    );
  }
}