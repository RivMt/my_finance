import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_api/core.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/navigator.dart';
import 'package:my_finance/page/categories_page.dart';
import 'package:my_finance/page/csv_page.dart';
import 'package:my_finance/page/read_csv_page.dart';
import 'package:my_finance/page/restore_items_page.dart';
import 'package:my_finance/page/preference_page.dart';

class MainMenuDialog extends StatefulWidget {
  const MainMenuDialog({
    super.key,
    required this.router,
    this.onAccountButtonPressed,
    this.onRefreshPressed,
  });

  final FinanceRouterDelegate router;

  final Function()? onAccountButtonPressed;

  final Function()? onRefreshPressed;

  @override
  State createState() => _MainMenuDialogState();
}

class _MainMenuDialogState extends State<MainMenuDialog> {

  /// Check host platform is desktop or not

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
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User
            UserCard(
              user: ApiClient().user,
              onTap: widget.onAccountButtonPressed,
              onLongPress: () => openPage(LoginPage(
                router: widget.router,
              )),
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
            // Trash can
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(LocaleKeys.trashCan.tr()),
              onTap: () => openPage(const RestoreItemsPage()),
            ),
            // CSV
            Visibility(
              visible: ScreenPlanner(context).isDesktop || kDebugMode,
              child: ListTile(
                leading: const Icon(Icons.table_view_outlined),
                title: Text(LocaleKeys.advancedQuery.tr()),
                onTap: () => openPage(const CsvPage()),
              ),
            ),
            // Load CSV
            ListTile(
              leading: const Icon(Icons.file_open_outlined),
              title: Text(LocaleKeys.readCsv.tr()),
              onTap: () => openPage(const ReadCsvPage()),
            ),
            const Divider(),
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