import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/page/account_details_page.dart';
import 'package:my_finance/page/categories_page.dart';
import 'package:my_finance/page/payment_details_page.dart';
import 'package:my_finance/local_provider.dart' as local_provider;

final _search = StateNotifierProvider<ModelStreamNotifier<Transaction>, Set<Transaction>>((ref) {
  return ModelStreamNotifier<Transaction>(ref);
});

class SearchFragment extends ConsumerStatefulWidget {
  const SearchFragment({
    super.key,
    required this.query,
  });

  final String query;

  @override
  ConsumerState createState() => _SearchFragmentState();
}

class _SearchFragmentState extends ConsumerState<SearchFragment> {

  void openCategoryPage() {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => const CategoriesPage(),
    ));
  }

  void openAccountPage(Account account) {
    ref.read(local_provider.selectedAccount.notifier).set(account.uuid);
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => const AccountDetailsPage(),
    ));
  }

  void openPaymentPage(Payment payment) {
    ref.read(local_provider.selectedPayment.notifier).set(payment.uuid);
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => const PaymentDetailsPage(),
    ));
  }

  void search() async {
    ref.read(_search.notifier).search(widget.query);
  }

  @override
  void didUpdateWidget(SearchFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      search();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.query.length < 3) {
      return MessageBox(
        icon: Icons.info_outline,
        message: LocaleKeys.msgInputSearchQuery.tr(),
      );
    }
    final List<Transaction> results = ref.watch(_search).toList(growable: false);
    if (results.isEmpty) {
      return MessageBox(
        icon: Icons.warning_amber_outlined,
        message: LocaleKeys.msgNoTransactions.tr(),
      );
    }
    return TransactionsFragment(items: results);
  }
}