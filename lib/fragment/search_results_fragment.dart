import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/page/accounts_page.dart';
import 'package:my_finance/page/payments_page.dart';

final _search = StateNotifierProvider<SearchState<FinanceSearchResult>, List<FinanceSearchResult>>((ref) {
  return SearchState<FinanceSearchResult>(ref);
});

class SearchResultsFragment extends ConsumerStatefulWidget {
  const SearchResultsFragment({
    super.key,
    required this.query,
  });

  final String query;

  @override
  _SearchResultsFragmentState createState() => _SearchResultsFragmentState();
}

class _SearchResultsFragmentState extends ConsumerState<SearchResultsFragment> {

  void openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  void request() async {
    ref.read(_search.notifier).request(widget.query);
  }

  @override
  void initState() {
    super.initState();
    request();
  }

  @override
  void didUpdateWidget(SearchResultsFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    final List<FinanceSearchResult> results = ref.watch(_search);
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        if (item.group == Account) {
          final data = item.convert() as Account;
          return AccountCard(
            data: data,
            onTap: () => openPage(AccountsPage(
              init: data,
            )),
          );
        } else if (item.group == Payment) {
          final data = item.convert() as Payment;
          return PaymentCard(
            data: data,
            onTap: () => openPage(PaymentsPage(
              init: data,
            )),
          );
        } else if (item.group == Transaction) {
          final data = item.convert() as Transaction;
          return TransactionCard(
            data: data,
            category: Category.unknown,
          );
        }
        return const SizedBox();
      },
    );
  }
}