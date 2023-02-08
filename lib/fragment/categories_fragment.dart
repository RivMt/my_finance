import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';

final _categories = StateNotifierProvider<FinanceModelState<Category>, List<Category>>((ref) {
  return FinanceModelState<Category>(ref);
});

class CategoriesFragment extends ConsumerStatefulWidget {
  const CategoriesFragment({
    super.key,
    this.conditions,
    this.onTap,
    this.onLongPress,
  });

  final List<Map<String, dynamic>>? conditions;

  final Function(Category)? onTap;

  final Function(Category)? onLongPress;

  @override
  _CategoriesFragmentState createState() => _CategoriesFragmentState();
}

class _CategoriesFragmentState extends ConsumerState<CategoriesFragment> {

  /// Request categories
  void request() {
    // Categories
    ref.read(_categories.notifier).request(widget.conditions ?? [{
      FinanceModel.keyDeleted: false,
    }], ApiClient().buildOptions(
      sortOrderType: SortOrderType.asc,
      sortOrderAttribute: FinanceModel.keyPid,
    ));
  }

  @override
  void initState() {
    super.initState();
    request();
  }

  @override
  void didUpdateWidget(CategoriesFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(_categories);
    final int panels = InterfaceConstructor.panelNumber(context);
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: panels,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: (MediaQuery.of(context).size.width / panels) / CategoryCard.height,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          category: category,
          onTap: () {
            if (widget.onTap != null) {
              widget.onTap!(category);
            }
          },
          onLongPress: () {
            if (widget.onLongPress != null) {
              widget.onLongPress!(category);
            }
          },
        );
      },
    );
  }
}