import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';

class AccountDetailsFragment extends ConsumerWidget {
  const AccountDetailsFragment({
    super.key,
    required this.account,
  });

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
        WalletItemIcon(
          icon: account.icon.icon,
          foreground: account.foreground,
          background: account.background,
        ),
      ],
    );
  }
}