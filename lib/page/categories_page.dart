import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/fragment/categories_fragment.dart';
import 'package:my_finance/modal/category_edit_modal.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

/// Manages expense and income categories in separate tabs.
class CategoriesPage extends ConsumerStatefulWidget {

  /// Legacy route name for category management.
  static const String route = "/categories";

  const CategoriesPage({super.key});

  @override
  ConsumerState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> with TickerProviderStateMixin {

  late final TabController tabController;

  final PageController pageController = PageController(
    initialPage: 0,
  );

  /// Shows the category creation or editing modal.
  void showCategoryEditingModal([Category? category]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) => Wrap(
        children: [
          CategoryEditModal(category),
        ],
      ),
    );
  }

  /// Synchronizes the page view with the selected tab.
  void onTabChanged(int index) {
    pageController.animateToPage(
      index,
      duration: tabController.animationDuration,
      curve: Curves.ease,
    );
  }

  @override
  void initState() {
    super.initState();
    // Keep the tab bar and page view in sync.
    tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(provider.categories);
    final expenses = categories.where((element) {
      return element.type == TransactionType.expense;
    }).toList(growable: false);
    final incomes = categories.where((element) {
      return element.type == TransactionType.income;
    }).toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.category.plural(2)),
        bottom: TabBar(
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: AppTheme.swatches.contentSecondary,
          controller: tabController,
          tabs: [
            Tab(text: LocaleKeys.transactionTypeExpense.tr(),),
            Tab(text: LocaleKeys.transactionTypeIncome.tr(),),
          ],
          onTap: onTabChanged,
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: pageController,
          children: [
            // Expense categories.
            CategoriesFragment(
              categories: expenses,
              onTap: showCategoryEditingModal,
            ),
            // Income categories.
            CategoriesFragment(
              categories: incomes,
              onTap: showCategoryEditingModal,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCategoryEditingModal(),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    tabController.dispose();
    pageController.dispose();
  }
}
