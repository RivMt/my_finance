import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/generated/locale_keys.g.dart';

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

  Future<ApiResponse> restoreItem(Category item) async {
    item.deleted = false;
    return await ApiClient().update<Category>([item.map]);
  }

  void onCategoryTapped(Category category, BuildContext context, WidgetRef ref) {
    if (category.deleted && isRestoreAvailable) {
      restoreItem(category).then((value) {
        // Escape if restore failed
        if (value.result != ApiResultCode.success) {
          return;
        }
        provider.refreshAccounts(ref);
        provider.refreshPayments(ref);
        final snackBar = SnackBar(
          content: Text(LocaleKeys.msgItemRestored.tr(args: [category.name])),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
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
          onTap: () => onCategoryTapped(category, context, ref),
          onLongPress: () => onCategoryLongPressed(category),
        );
      },
    );
  }
}