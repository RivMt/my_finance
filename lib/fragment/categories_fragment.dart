import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;

class CategoriesFragment extends ConsumerStatefulWidget {
  const CategoriesFragment({
    super.key,
    this.onTap,
    this.onLongPress,
  });

  final Function(Category)? onTap;

  final Function(Category)? onLongPress;

  @override
  ConsumerState createState() => _CategoriesFragmentState();
}

class _CategoriesFragmentState extends ConsumerState<CategoriesFragment> {

  /// Request categories
  void request() => provider.refreshCategories(ref);

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(provider.filteredCategories);
    final int panels = ScreenPlanner(context).panelNumber;
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
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