import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/fragment/categories_fragment.dart';
import 'package:my_finance/fragment/category_edit_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class CategoriesPage extends ConsumerStatefulWidget {

  static const String route = "/categories";

  const CategoriesPage({super.key});

  @override
  ConsumerState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> with TickerProviderStateMixin {

  late final TabController tabController;

  /// Show [CategoryEditFragment]
  void showCategoryEditingModal([Category? category]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) => Wrap(
        children: [
          CategoryEditFragment(
            base: category,
            onFinish: (item) => Navigator.pop(context, item),
          ),
        ],
      ),
    ).then((value) {
      provider.refreshCategories(ref);
    });
  }

  @override
  void initState() {
    super.initState();
    // Tab controller
    tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.category.plural(2)),
        bottom: TabBar(
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: AppTheme.subtext,
          controller: tabController,
          tabs: [
            Tab(text: LocaleKeys.transactionTypeExpense.tr(),),
            Tab(text: LocaleKeys.transactionTypeIncome.tr(),),
          ],
          onTap: (index) => setState(() {
            ref.read(provider.transactionTypeFilter.notifier).set(TransactionType.fromCode(index));
          }),
        ),
      ),
      body: SafeArea(
        child: CategoriesFragment(
          onTap: showCategoryEditingModal,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCategoryEditingModal(),
        child: const Icon(Icons.add),
      ),
    );
  }
}