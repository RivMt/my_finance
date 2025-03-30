import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class CategoryEditModal extends StatefulWidget {
  const CategoryEditModal({
    super.key,
    this.base,
    required this.onFinish,
  });
  
  final Category? base;

  final Function(Category?) onFinish;

  @override
  State createState() => _CategoryEditModalState();
}

class _CategoryEditModalState extends State<CategoryEditModal> {

  final TextEditingController nameController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  /// Is this fragment editing [Category]
  ///
  /// This returns `true` when [widget.base] is not `null`
  bool get isEdit => widget.base != null;

  /// [Category] which is now editing
  Category editing = Category({});

  /// Value is [editing] is ready or not
  bool get ready => editing.isValid;

  /// Show [CategoryIcon] item selection dialog
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

  /// Triggers on negative button pressed
  Future<bool> onNegativeButtonPressed() async {
    // Escape on creating mode
    if (!isEdit) {
      widget.onFinish(null);
    }
    final ApiResponse<Category> result = await ApiClient().delete<Category>(widget.base!.uuid);
    // Check failed
    if (result.result != ApiResultCode.success) {
      return false;
    }
    // Complete
    widget.onFinish(result.data);
    return true;
  }

  /// Triggers on confirm button pressed
  Future<bool> onConfirmButtonPressed() async {
    late ApiResponse<Category> result;
    // Send
    if (isEdit) {
      result = await ApiClient().update<Category>(editing.map);
    } else {
      result = await ApiClient().create<Category>(editing.map);
    }
    // Check
    if (result.result != ApiResultCode.success) {
      // Failed
      return false;
    }
    // Complete
    widget.onFinish(result.data);
    return true;
  }

  /// Trigger on type chips selected
  void onTypeChanged(TransactionType type, bool value) {
    setState(() {
      if (value) {
        editing.type = type;
      }
    });
  }

  /// Triggers on name changed
  void onNameChanged(String name) {
    setState(() {
      editing.name = name;
    });
  }

  /// Triggers on description changed
  void onDescriptionsChanged(String desc) {
    setState(() {
      editing.descriptions = desc;
    });
  }

  /// Triggers on [CategoryIcon] button pressed
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

  /// Triggers on cash checkboxes value changed
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
          // Basic information
          Text(
            LocaleKeys.basicInfo.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8,),
          // Type
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
          // Name
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
          // Description
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(
                labelText: LocaleKeys.description.tr(),
                prefixIcon: const Icon(Icons.notes_outlined)
            ),
            onChanged: onDescriptionsChanged,
          ),
          const SizedBox(height: 8,),
          // Included checkbox
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