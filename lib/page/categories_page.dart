import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/fragment/categories_fragment.dart';
import 'package:my_finance/modal/category_edit_modal.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class CategoriesPage extends ConsumerStatefulWidget {

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

  /// Show [CategoryEditModal]
  void showCategoryEditingModal([Category? category]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) => Wrap(
        children: [
          CategoryEditModal(
            base: category,
            onFinish: (item) => Navigator.pop(context, item),
          ),
        ],
      ),
    ).then((value) {
      provider.refreshCategories(ref);
    });
  }

  /// On tab page changed
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
    // Tab controller
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
            // Expenses
            CategoriesFragment(
              categories: expenses,
              onTap: showCategoryEditingModal,
            ),
            // Incomes
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