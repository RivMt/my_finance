import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/navigator.dart';
import 'package:my_finance/page/categories_page.dart';
import 'package:my_finance/page/advanced_query_page.dart';
import 'package:my_finance/page/read_csv_page.dart';
import 'package:my_finance/page/restore_items_page.dart';
import 'package:my_finance/page/preference_page.dart';

class MainMenuDialog extends ConsumerStatefulWidget {
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
  ConsumerState createState() => _MainMenuDialogState();
}

class _MainMenuDialogState extends ConsumerState<MainMenuDialog> {

  /// Check host platform is desktop or not

  /// Open [page]
  ///
  /// After [page] has been pop, triggers [onPageFinished] if it is not `null`.
  void openPage(RoutePath configuration) {
    widget.router.setNewRoutePath(configuration);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(provider.currentUser).user;
    return AlertDialog(
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User
            UserCard(
              user: user,
              onTap: widget.onAccountButtonPressed,
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
              onTap: () => openPage(FinanceRoutePath.categories),
            ),
            // Trash can
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(LocaleKeys.trashCan.tr()),
              onTap: () => openPage(FinanceRoutePath.restores),
            ),
            // CSV
            Visibility(
              visible: ScreenPlanner(context).isDesktop || kDebugMode,
              child: ListTile(
                leading: const Icon(Icons.table_view_outlined),
                title: Text(LocaleKeys.advancedQuery.tr()),
                onTap: () => openPage(FinanceRoutePath.advancedQuery),
              ),
            ),
            // Load CSV
            ListTile(
              leading: const Icon(Icons.file_open_outlined),
              title: Text(LocaleKeys.readCsv.tr()),
              onTap: () => openPage(FinanceRoutePath.readCsv),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(LocaleKeys.settings.tr()),
              onTap: () => openPage(FinanceRoutePath.preferences),
            ),
          ],
        ),
      ),
    );
  }
}