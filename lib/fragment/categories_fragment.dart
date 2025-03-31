import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;

class CategoriesFragment extends ConsumerWidget {
  const CategoriesFragment({
    super.key,
    required this.categories,
    this.isRestoreAvailable = true,
    this.onTap,
    this.onLongPress,
  });

  final List<Category> categories;

  final bool isRestoreAvailable;

  final Function(Category)? onTap;

  final Function(Category)? onLongPress;

  Future<bool> restoreItem(WidgetRef ref, Category category) async {
    category.deleted = false;
    return await provider.updateCategory(ref, category);
  }

  void onCategoryTapped(WidgetRef ref, Category category, ) {
    if (category.deleted && isRestoreAvailable) {
      restoreItem(ref, category);
      return;
    }
    if (onTap != null) {
      onTap!(category);
    }
  }

  void onCategoryLongPressed(Category category) {
    if (onLongPress != null) {
      onLongPress!(category);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onTap: () => onCategoryTapped(ref, category),
          onLongPress: () => onCategoryLongPressed(category),
        );
      },
    );
  }
}