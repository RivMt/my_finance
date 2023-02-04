import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/fragment/account_details_fragment.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

final _accounts = StateNotifierProvider<FinanceModelState<Account>, List<Account>>((ref) {
  return FinanceModelState<Account>(ref);
});

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
    ref.read(_accounts.notifier).request([{
      FinanceModel.keyPid: widget.pid,
    }]);
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
    late Account? account;
    if (ref.watch(_accounts).isNotEmpty) {
      account = ref.watch(_accounts)[0];
    } else {
      account = null;
    }
    return Scaffold(
      body: IndexedStack(
        index: account == null ? 0 : 1,
        children: [
          // 0: No account
          MessageBox(
            icon: Icons.question_mark_outlined,
            message: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
              "object": LocaleKeys.account.plural(1),
            }),
          ),
          // 1: Account details
          CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(account!.descriptions),
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
          )
        ],
      ),
    );
  }
}