import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/fragment/account_details_fragment.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/provider/finance_provider.dart';

class AccountDetailsPage extends ConsumerStatefulWidget {
  const AccountDetailsPage({
    super.key,
    required this.pid,
  });
  
  final int pid;

  @override
  _AccountDetailsPageState createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends ConsumerState<AccountDetailsPage> {
  
  /// Request account using [widget.pid]
  void request() {
    ref.read(FinanceProvider.account.notifier).request({
      FinanceModel.keyPid: widget.pid
    });
  }

  @override
  void initState() {
    super.initState();
    request();
  }

  @override
  void didUpdateWidget(AccountDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    final Account account = ref.watch(FinanceProvider.account) ?? Account.unknown;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(account.descriptions),
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
            sliver: SliverToBoxAdapter(
              child: AccountDetailsFragment(
                account: account,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: TransactionsFragment(
              useSliver: true,
              condition: {
                Transaction.keyAccountID: account.pid,
              },
            ),
          ),
        ],
      ),
    );
  }
}