import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/navigator.dart';

/// Provides user actions and navigation to finance management pages.
class MainMenuDialog extends ConsumerStatefulWidget {
  const MainMenuDialog({
    super.key,
    required this.router,
    this.onAccountButtonPressed,
    this.onRefreshPressed,
  });

  /// Router used to open menu destinations.
  final FinanceRouterDelegate router;

  /// Called when the user card is tapped.
  final Function()? onAccountButtonPressed;

  /// Called when refresh is requested.
  final Function()? onRefreshPressed;

  @override
  ConsumerState createState() => _MainMenuDialogState();
}

class _MainMenuDialogState extends ConsumerState<MainMenuDialog> {

  /// Opens the page represented by [configuration].
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
            // Current user.
            UserCard(
              user: user,
              onTap: widget.onAccountButtonPressed,
            ),
            const Divider(),
            // Data refresh.
            ListTile(
              leading: const Icon(Icons.refresh_outlined),
              title: Text(LocaleKeys.refresh.tr()),
              onTap: widget.onRefreshPressed,
            ),
            const Divider(),
            // Category settings.
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: Text(LocaleKeys.object_action.tr(namedArgs: {
                "object": LocaleKeys.category.plural(2),
                "action": LocaleKeys.edit.tr(),
              })),
              onTap: () => openPage(FinanceRoutePath.categories),
            ),
            // Deleted items.
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(LocaleKeys.trashCan.tr()),
              onTap: () => openPage(FinanceRoutePath.restores),
            ),
            // Advanced CSV export.
            Visibility(
              visible: ScreenPlanner(context).isDesktop || kDebugMode,
              child: ListTile(
                leading: const Icon(Icons.table_view_outlined),
                title: Text(LocaleKeys.advancedQuery.tr()),
                onTap: () => openPage(FinanceRoutePath.advancedQuery),
              ),
            ),
            // CSV import.
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
