import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/fragment/categories_fragment.dart';
import 'package:my_finance/fragment/category_edit_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

final _categories = StateNotifierProvider<FinanceModelState<Category>, List<Category>>((ref) {
  return FinanceModelState<Category>(ref);
});

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> with TickerProviderStateMixin {

  late final TabController tabController;

  Category? selected;

  /// Request categories
  void request() {
    // Categories
    ref.read(_categories.notifier).request([{
      FinanceModel.keyDeleted: false,
    }], ApiClient().buildOptions(
      sortOrderType: SortOrderType.asc,
      sortOrderAttribute: FinanceModel.keyPid,
    ));
  }

  /// Triggers on category selected
  void onCategorySelected(Category category) {
    setState(() {
      selected = category;
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
    // Request
    request();
  }

  @override
  void didUpdateWidget(CategoriesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width / InterfaceConstructor.panelNumber(context);
    final categories = ref.watch(_categories).where((item) {
      return item.type == TransactionType.fromCode(tabController.index);
    }).toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.category.plural(2)),
        bottom: TabBar(
          controller: tabController,
          tabs: [
            Tab(text: LocaleKeys.expense.tr(),),
            Tab(text: LocaleKeys.income.tr(),),
          ],
        ),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories
          SizedBox(
            width: width,
            child: CategoriesFragment(
              categories: categories,
              onTap: onCategorySelected,
            ),
          ),
          // Edit
          SizedBox(
            width: width,
            child: IndexedStack(
              index: selected == null ? 0 : 1,
              children: [
                // 0
                MessageBox(
                  icon: Icons.question_mark_outlined,
                  message: LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
                    "object": LocaleKeys.category.plural(1),
                  }),
                ),
                // 1
                Card(
                  child: CategoryEditFragment(
                    base: selected,
                    onFinish: (result) {
                      request();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}