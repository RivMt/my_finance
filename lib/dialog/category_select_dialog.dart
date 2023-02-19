import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/core/screen_planner.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class CategorySelectDialog extends StatefulWidget {
  const CategorySelectDialog({
    super.key,
    required this.list,
    this.onTap,
  });

  /// List of **ALL** [Category]s
  final List<Category> list;

  /// Triggers on [CategoryCard] tapped
  final Function(Category)? onTap;

  @override
  _CategorySelectDialogState createState() => _CategorySelectDialogState();
}

class _CategorySelectDialogState extends State<CategorySelectDialog> {

  List<Category> categories = [];

  /// Currently selected [TransactionType]
  TransactionType selectedType = TransactionType.expense;

  /// Value of including [Transaction.keyIncluded] is `true`
  bool include = true;

  /// Triggers on chip selection changed
  void onChipSelected(TransactionType type) {
    selectedType = type;
    refresh();
    setState(() {});
  }

  /// Triggers on included checkbox pressed
  void onIncludedPressed(bool value) {
    include = value;
    refresh();
    setState(() {});
  }

  /// Refresh list of categories according to conditions
  void refresh() {
    categories = widget.list.where((item) {
      return item.type == selectedType && item.isIncluded == include;
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void didUpdateWidget(CategorySelectDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocaleKeys.object_action.tr(namedArgs: {
        "object": LocaleKeys.category.plural(1),
        "action": LocaleKeys.select.tr(),
      })),
      content: SizedBox(
        width: ScreenPlanner(context).dialogWidth,
        height: ScreenPlanner(context).dialogHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type
                Wrap(
                  spacing: 4,
                  children: TransactionType.types.map((type) {
                    return ChoiceChip(
                      label: Text(type.key.tr()),
                      selected: selectedType == type,
                      onSelected: (value) => onChipSelected(type),
                    );
                  }).toList(growable: false),
                ),
                // Included
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Checkbox(
                      value: include,
                      onChanged: (value) => onIncludedPressed(value ?? false),
                    ),
                    Text(
                      LocaleKeys.included.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            // List of categories
            Expanded(
              child: ListView.builder(
                itemCount: widget.list.length,
                itemBuilder: (context, index) {
                  final item = widget.list[index];
                  return CategoryCard(
                    category: item,
                    onTap: () {
                      if (widget.onTap != null) {
                        widget.onTap!(item);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}