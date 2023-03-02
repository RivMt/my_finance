import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/dialog/transaction_details_dialog.dart';
import 'package:my_finance/page/accounts_page.dart';
import 'package:my_finance/page/payments_page.dart';

final _search = StateNotifierProvider<SearchState<FinanceSearchResult>, List<FinanceSearchResult>>((ref) {
  return SearchState<FinanceSearchResult>(ref);
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
  void didUpdateWidget(SearchFragment oldWidget) {
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
        switch(item.table) {
          case FinanceModelType.account:
            final data = Account(item.map);
            return AccountCard(
              data: data,
              onTap: () => openPage(AccountsPage(
                init: data,
              )),
            );
          case FinanceModelType.payment:
            final data = Payment(item.map);
            return PaymentCard(
              data: data,
              onTap: () => openPage(PaymentsPage(
                init: data,
                paymentCondition: const [{
                  ModelKeys.keyPid: {
                    "min": 0,
                  }
                }],
              )),
            );
          case FinanceModelType.transaction:
            final data = Transaction(item.map);
            return TransactionCard(
              data: data,
              category: Category.unknown,
              onTap: () => showDialog(
                context: context,
                builder: (context) => TransactionDetailsDialog(
                  data: data,
                ),
              ),
            );
          case FinanceModelType.category:
            final data = Category(item.map);
            return CategoryCard(
              category: data,
            );
        }
        return const SizedBox();
      },
    );
  }
}