import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/generated/locale_keys.g.dart';

/// Creates, updates, or soft-deletes a [Category].
class CategoryEditModal extends ConsumerStatefulWidget {
  const CategoryEditModal(this.base, {super.key});
  
  /// Category to edit, or `null` when creating one.
  final Category? base;

  @override
  ConsumerState createState() => _CategoryEditModalState();
}

class _CategoryEditModalState extends ConsumerState<CategoryEditModal> {

  final TextEditingController nameController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  /// Whether an existing category is being edited.
  bool get isEdit => widget.base != null;

  /// Mutable category being edited.
  Category editing = Category({});

  /// Whether the category is valid.
  bool get ready => editing.isValid;

  /// Shows a [CategorySymbol] selection dialog.
  Future<CategorySymbol?> showSelectDialog(BuildContext context, String title, List<CategorySymbol> list) async {
    return await showDialog(
      context: context,
      builder: (context) {
        const double size = 32;
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: ScreenPlanner(context).dialogWidth,
            height: MediaQuery.of(context).size.height * 0.7,
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: size + 16,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final category = list[index];
                return IconButton(
                  icon: Icon(
                    size: size,
                    category.icon,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                  onPressed: () => Navigator.pop(context, category),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Deletes the category in edit mode or cancels creation.
  Future<bool> onNegativeButtonPressed() async {
    if (!isEdit) {
      return true;
    }
    return await provider.deleteCategory(ref, editing);
  }

  /// Persists the category being edited.
  Future<bool> onConfirmButtonPressed() async {
    if (isEdit) {
      return await provider.updateCategory(ref, editing);
    }
    return await provider.createCategory(ref, editing);
  }

  /// Updates the category transaction type.
  void onTypeChanged(TransactionType type, bool value) {
    setState(() {
      if (value) {
        editing.type = type;
      }
    });
  }

  /// Updates the category name.
  void onNameChanged(String name) {
    setState(() {
      editing.name = name;
    });
  }

  /// Updates the category description.
  void onDescriptionsChanged(String desc) {
    setState(() {
      editing.descriptions = desc;
    });
  }

  /// Selects the category symbol.
  void onCategoryIconButtonPressed() async {
    final icon = await showSelectDialog(
      context,
      LocaleKeys.icon.tr(),
      CategorySymbol.values,
    );
    if (icon != null) {
      setState(() {
        editing.icon = icon;
      });
    }
  }

  /// Updates whether related transactions are included in statistics.
  void onIncludeValueChanged(bool value) {
    setState(() {
      editing.isIncluded = value;
    });
  }

  @override
  void initState() {
    super.initState();
    editing = widget.base ?? Category({});
    nameController.text = editing.name;
    descriptionController.text = editing.descriptions;
  }

  @override
  Widget build(BuildContext context) {
    return Modal(
      title: LocaleKeys.object_action.tr(namedArgs: {
        "object": LocaleKeys.category.plural(1),
        "action": isEdit ? LocaleKeys.edit.tr() : LocaleKeys.add.tr(),
      }),
      positiveButtonTitle: LocaleKeys.confirm.tr(),
      negativeButtonTitle: isEdit ? LocaleKeys.delete.tr() : LocaleKeys.cancel.tr(),
      onPositiveButtonPressed: onConfirmButtonPressed,
      onNegativeButtonPressed: onNegativeButtonPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic information.
          Text(
            LocaleKeys.basicInfo.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8,),
          // Transaction type.
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  LocaleKeys.type.tr(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: TransactionType.types.map((type) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                      child: ChoiceChip(
                        label: Text(type.key.tr()),
                        selected: type == editing.type,
                        onSelected: (bool value) => onTypeChanged(type, value),
                      ),
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8,),
          // Name and symbol.
          TextField(
            controller: nameController,
            decoration: InputDecoration(
                labelText: LocaleKeys.name.tr(),
                prefixIcon: IconButton(
                  icon: Icon(editing.icon.icon),
                  onPressed: () => onCategoryIconButtonPressed(),
                )
            ),
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 8,),
          // Description.
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(
                labelText: LocaleKeys.description.tr(),
                prefixIcon: const Icon(Icons.notes_outlined)
            ),
            onChanged: onDescriptionsChanged,
          ),
          const SizedBox(height: 8,),
          // Statistics-inclusion flag.
          Padding(
            padding: const EdgeInsets.all(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onIncludeValueChanged(!editing.isIncluded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Checkbox(
                      value: editing.isIncluded,
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
    );
  }
}
