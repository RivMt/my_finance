import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/generated/locale_keys.g.dart';

final _type = StateNotifierProvider<ValueStateNotifier<TransactionType>, TransactionType>((ref) {
  return ValueStateNotifier(ref, TransactionType.expense);
});

final _included = StateNotifierProvider<ValueStateNotifier<bool>, bool>((ref) {
  return ValueStateNotifier(ref, true);
});

final _categories = Provider((ref) {
  final type = ref.watch(_type);
  final included = ref.watch(_included);
  final categories = ref.watch(provider.categories);
  return categories.where((item) {
    return item.type == type
        && item.isIncluded == included
        && item.deleted == false;
  }).toList(growable: false);
});

class CategorySelectDialog extends ConsumerStatefulWidget {
  const CategorySelectDialog({
    super.key,
    this.selectedType = TransactionType.expense,
    this.showIncluded = true,
    this.onTap,
  });

  /// Currently selected [TransactionType]
  final TransactionType selectedType;

  /// Value of including [Transaction.keyIncluded] is `true`
  final bool showIncluded;

  /// Triggers on [CategoryCard] tapped
  final Function(Category)? onTap;

  @override
  ConsumerState createState() => _CategorySelectDialogState();
}

class _CategorySelectDialogState extends ConsumerState<CategorySelectDialog> {

  /// Triggers on chip selection changed
  void onChipSelected(TransactionType type) {
    ref.read(_type.notifier).set(type);
  }

  /// Triggers on included checkbox pressed
  void onIncludedPressed(bool value) {
    ref.read(_included.notifier).set(value);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      onChipSelected(widget.selectedType);
      onIncludedPressed(widget.showIncluded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = ref.watch(_type);
    final showIncluded = ref.watch(_included);
    final categories = ref.watch(_categories);
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onIncludedPressed(!showIncluded),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Checkbox(
                            value: showIncluded,
                            onChanged: null,
                          ),
                          Text(
                            LocaleKeys.included.tr(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // List of categories
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final item = categories[index];
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