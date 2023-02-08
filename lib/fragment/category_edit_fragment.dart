import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

class CategoryEditFragment extends StatefulWidget {
  const CategoryEditFragment({
    super.key,
    this.base,
    required this.onFinish,
  });
  
  final Category? base;

  final Function(Category?) onFinish;

  @override
  _CategoryEditFragmentState createState() => _CategoryEditFragmentState();
}

class _CategoryEditFragmentState extends State<CategoryEditFragment> {

  final TextEditingController nameController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  /// Is this fragment editing [Category]
  ///
  /// This returns `true` when [widget.base] is not `null`
  bool get isEdit => widget.base != null;

  /// [Category] which is now editing
  Category editing = Category({});

  /// Value of sent [editing] and waiting for response
  bool _progressing = false;

  /// Value of sent [editing] and waiting for response
  ///
  /// This is wrapper of [_progressing]. When setting this, [setState] called
  /// automatically
  bool get progressing => _progressing;

  set progressing(bool value) {
    _progressing = value;
    setState(() {});
  }

  /// Show [CategoryIcon] item selection dialog
  Future<CategorySymbol> showSelectDialog(BuildContext context, String title, List<CategorySymbol> list) async {
    return await showDialog(
      context: context,
      builder: (context) {
        const double size = 32;
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: (MediaQuery.of(context).size.width / InterfaceConstructor.panelNumber(context)) * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: size,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final category = list[index];
                return SizedBox(
                  width: size,
                  height: size,
                  child: IconButton(
                    icon: Icon(
                      category.icon,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    onPressed: () => Navigator.pop(context, category),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Triggers on negative button pressed
  void onNegativeButtonPressed() async {
    // Escape on creating mode
    if (!isEdit) {
      widget.onFinish(null);
    }
    progressing = true;
    final ApiResponse<List<Category>> result = await ApiClient().delete([widget.base!.map]);
    progressing = false;
    // Check failed
    if (result.result != ApiResultCode.success && result.data.length != 1) {
      return;
    }
    // Complete
    widget.onFinish(result.data[0]);
  }

  /// Triggers on confirm button pressed
  void onConfirmButtonPressed() async {
    late ApiResponse<List<Category>> result;
    progressing = true;
    // Send
    if (isEdit) {
      result = await ApiClient().update([editing.map]);
    } else {
      result = await ApiClient().create([editing.map]);
    }
    // Check
    progressing = false;
    if (result.result != ApiResultCode.success || result.data.length != 1) {
      // Failed
      return;
    }
    // Complete
    widget.onFinish(result.data[0]);
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
    editing.name = name;
    setState(() {});
  }

  /// Triggers on description changed
  void onDescriptionsChanged(String desc) {
    editing.descriptions = desc;
    setState(() {});
  }

  /// Triggers on [CategoryIcon] button pressed
  void onCategoryIconButtonPressed() async {
    final icon = await showSelectDialog(
      context,
      LocaleKeys.icon.tr(),
      CategorySymbol.values,
    );
    editing.icon = icon;
    setState(() {});
  }

  /// Triggers on cash checkboxes value changed
  void onIncludeValueChanged(bool value) {
    editing.included = value;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    editing = widget.base ?? Category({});
    nameController.text = editing.name;
    descriptionController.text = editing.descriptions;
  }

  @override
  void didUpdateWidget(CategoryEditFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    editing = widget.base ?? Category({});
    nameController.text = editing.name;
    descriptionController.text = editing.descriptions;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ModalHeader(
            disabled: progressing,
            headerTitle: LocaleKeys.object_action.tr(namedArgs: {
              "object": LocaleKeys.category.plural(1),
              "action": isEdit ? LocaleKeys.edit.tr() : LocaleKeys.add.tr(),
            }),
            positiveButtonTitle: LocaleKeys.confirm.tr(),
            negativeButtonTitle: isEdit ? LocaleKeys.delete.tr() : LocaleKeys.cancel.tr(),
            onPositiveButtonPressed: progressing ? null : onConfirmButtonPressed,
            onNegativeButtonPressed: progressing ? null : onNegativeButtonPressed,
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(8),
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
                        children: TransactionType.values.map((type) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                            child: ChoiceChip(
                              label: Text(type.name.tr()),
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
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Checkbox(
                        value: editing.included,
                        onChanged: (value) => onIncludeValueChanged(value ?? false),
                      ),
                      Text(
                        LocaleKeys.included.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Progress
          Visibility(
            visible: progressing,
            child: const LinearProgressIndicator(value: null,),
          ),
        ],
      ),
    );
  }
}