import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/transactions_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

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