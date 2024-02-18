import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_finance/navigator.dart';
import 'package:my_api/core/widget/register_page.dart';
import 'package:my_finance/page/categories_page.dart';
import 'package:my_finance/page/csv_page.dart';
import 'package:my_finance/page/home_page.dart';
import 'package:my_finance/page/payments_page.dart';
import 'package:my_finance/page/preference_page.dart';
import 'package:my_finance/page/restore_items_page.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MyFinance',
      theme: AppTheme.light(Colors.blue),
      darkTheme: AppTheme.dark(Colors.blue),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerDelegate: FinanceRouterDelegate(),
      routeInformationParser: FinanceRouteParser(),
      initialRoute: HomePage.route,
      routes: {
        HomePage.route: (context) => const HomePage(),
        LoginPage.route: (context) => const LoginPage(),
        RegisterPage.route: (context) => const RegisterPage(),
        PaymentsPage.route: (context) => const PaymentsPage(),
        CategoriesPage.route: (context) => const CategoriesPage(),
        PreferencePage.route: (context) => const PreferencePage(),
        RestoreItemsPage.routeTrash: (context) => const RestoreItemsPage(type: RestoreItemType.deleted),
        RestoreItemsPage.routeInvisible: (context) => const RestoreItemsPage(type: RestoreItemType.visible),
        CsvPage.route: (context) => const CsvPage(),
      },
    );
  }
}