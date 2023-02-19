import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/categories_fragment.dart';
import 'package:my_finance/fragment/category_edit_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> with TickerProviderStateMixin {

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
      setState(() {});
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
          controller: tabController,
          tabs: [
            Tab(text: LocaleKeys.transactionTypeExpense.tr(),),
            Tab(text: LocaleKeys.transactionTypeIncome.tr(),),
          ],
          onTap: (index) => setState(() {}),
        ),
      ),
      body: SafeArea(
        child: CategoriesFragment(
          conditions: [{
            Category.keyType: tabController.index,
            FinanceModel.keyDeleted: false,
          }],
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