import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';

final _search = StateNotifierProvider<SearchState<FinanceSearchResult>, List<FinanceSearchResult>>((ref) {
  return SearchState<FinanceSearchResult>(ref);
});

final _categories = StateNotifierProvider<ModelsState<Category>, List<Category>>((ref) {
  return ModelsState<Category>(ref);
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
          return AccountCard(
            data: item.convert() as Account,
          );
        } else if (item.group == Payment) {
          return PaymentCard(
            data: item.convert() as Payment,
          );
        } else if (item.group == Transaction) {
          return TransactionCard(
            data: item.convert() as Transaction,
            // TODO: Set category
            category: Category.unknown,
          );
        }
        return const SizedBox();
      },
    );
  }
}