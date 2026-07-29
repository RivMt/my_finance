import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;

/// Displays categories and optionally restores soft-deleted entries.
class CategoriesFragment extends ConsumerWidget {
  const CategoriesFragment({
    super.key,
    required this.categories,
    this.isRestoreAvailable = true,
    this.onTap,
    this.onLongPress,
  });

  /// Categories to display.
  final List<Category> categories;

  /// Whether tapping a deleted category restores it.
  final bool isRestoreAvailable;

  /// Called when an active category is tapped.
  final Function(Category)? onTap;

  /// Called when a category is long-pressed.
  final Function(Category)? onLongPress;

  /// Restores a soft-deleted [category].
  Future<bool> restoreItem(WidgetRef ref, Category category) async {
    category.deleted = false;
    return await provider.updateCategory(ref, category);
  }

  /// Restores or reports the tapped [category].
  void onCategoryTapped(WidgetRef ref, Category category, ) {
    if (category.deleted && isRestoreAvailable) {
      restoreItem(ref, category);
      return;
    }
    if (onTap != null) {
      onTap!(category);
    }
  }

  /// Reports a long press on [category].
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
