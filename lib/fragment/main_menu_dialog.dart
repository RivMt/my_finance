import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/page/categories_page.dart';

class MainMenuDialog extends StatefulWidget {
  const MainMenuDialog({
    super.key,
    this.onRefreshPressed,
  });

  final Function()? onRefreshPressed;

  @override
  _MainMenuDialogState createState() => _MainMenuDialogState();
}

class _MainMenuDialogState extends State<MainMenuDialog> {

  void openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // User
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(LocaleKeys.full_name.tr(namedArgs: {
              "first": ApiCore().user.firstName,
              "last": ApiCore().user.lastName,
            })),
            subtitle: Text(ApiCore().user.email),
          ),
          const Divider(),
          // Refresh
          ListTile(
            leading: const Icon(Icons.refresh_outlined),
            title: Text(LocaleKeys.refresh.tr()),
          ),
          const Divider(),
          // Settings
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(LocaleKeys.object_action.tr(namedArgs: {
              "object": LocaleKeys.category.plural(2),
              "action": LocaleKeys.edit.tr(),
            })),
            onTap: () => openPage(const CategoriesPage()),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(LocaleKeys.settings.tr()),
          ),
        ],
      ),
    );
  }
}