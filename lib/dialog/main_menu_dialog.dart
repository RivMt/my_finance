import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_api/core.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/page/categories_page.dart';
import 'package:my_finance/page/preference_page.dart';

class MainMenuDialog extends StatefulWidget {
  const MainMenuDialog({
    super.key,
    this.onAccountButtonPressed,
    this.onRefreshPressed,
  });

  final Function()? onAccountButtonPressed;

  final Function()? onRefreshPressed;

  @override
  _MainMenuDialogState createState() => _MainMenuDialogState();
}

class _MainMenuDialogState extends State<MainMenuDialog> {

  /// Open [page]
  ///
  /// After [page] has been pop, triggers [onPageFinished] if it is not `null`.
  void openPage(Widget page, [Function(dynamic)? onPageFinished]) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page)).then((value) {
      if (onPageFinished != null) {
        onPageFinished(value);
      }
    });
  }

  /// Triggers on test mode tile tapped
  void onTestModeTapped() async {
    final Map<String, dynamic> prefs = jsonDecode(await rootBundle.loadString("assets/key/server.json"));
    await ApiClient().init(
      onLoginRequired: () {},
      preferences: prefs,
      useTest: ApiClient().serverType == ServerType.production,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User
            UserCard(
              user: ApiClient().user,
              onTap: widget.onAccountButtonPressed,
              onLongPress: () => openPage(const LoginPage()),
            ),
            const Divider(),
            // Refresh
            ListTile(
              leading: const Icon(Icons.refresh_outlined),
              title: Text(LocaleKeys.refresh.tr()),
              onTap: widget.onRefreshPressed,
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
            const Divider(),
            Visibility(
              visible: kDebugMode,
              child: ListTile(
                leading: Icon(ApiClient().serverType == ServerType.production
                    ? Icons.work_outline_outlined
                    : Icons.adb_outlined
                ),
                title: Text(ApiClient().serverType == ServerType.production
                    ? LocaleKeys.productionMode.tr()
                    : LocaleKeys.testMode.tr()
                ),
                onTap: onTestModeTapped,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(LocaleKeys.settings.tr()),
              onTap: () => openPage(
                const PreferencePage(),
                (item) {
                  if (widget.onRefreshPressed != null) {
                    widget.onRefreshPressed!();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}