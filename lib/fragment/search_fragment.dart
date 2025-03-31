import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/dialog/transaction_details_dialog.dart';
import 'package:my_finance/page/account_details_page.dart';
import 'package:my_finance/page/categories_page.dart';
import 'package:my_finance/page/payment_details_page.dart';
import 'package:my_finance/local_provider.dart' as local_provider;

/*final _search = StateNotifierProvider<SearchState<FinanceSearchResult>, List<FinanceSearchResult>>((ref) {
  return SearchState<FinanceSearchResult>(ref);
});*/

final _categories = StateNotifierProvider<ModelsState<Category>, List<Category>>((ref) {
  return ModelsState<Category>(ref);
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

  void getCategories() async {
    // Get categories
    await ref.read(_categories.notifier).fetch({});
  }

  void request() async {
    // Search
    //ref.read(_search.notifier).request(widget.query);
  }

  @override
  void initState() {
    super.initState();
    getCategories();
    request();
  }

  @override
  void didUpdateWidget(SearchFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    final List<FinanceSearchResult> results = [];//ref.watch(_search);
    final List<Category> categories = ref.watch(_categories);
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        switch(item.table) {
          case FinanceModelType.account:
            final data = Account(item.map);
            return AccountCard(
              data: data,
              onTap: () => openAccountPage(data),
            );
          case FinanceModelType.payment:
            final data = Payment(item.map);
            return PaymentCard(
              data: data,
              onTap: () => openPaymentPage(data),
            );
          case FinanceModelType.transaction:
            final data = Transaction(item.map);
            return TransactionCard(
              data: data,
              category: categories.firstWhere((item) => item.uuid == data.categoryId, orElse: () => Category.unknown),
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
              onTap: () => openCategoryPage(),
            );
        }
        return const SizedBox();
      },
    );
  }
}