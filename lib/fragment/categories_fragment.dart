import 'package:flutter/material.dart';
import 'package:my_api/my_api.dart';

class CategoriesFragment extends StatefulWidget {
  const CategoriesFragment({
    super.key,
    this.categories = const [],
    this.onTap,
    this.onLongPress,
  });

  final List<Category> categories;

  final Function(Category)? onTap;

  final Function(Category)? onLongPress;

  @override
  _CategoriesFragmentState createState() => _CategoriesFragmentState();
}

class _CategoriesFragmentState extends State<CategoriesFragment> {

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.categories.length,
      itemBuilder: (context, index) {
        final category = widget.categories[index];
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