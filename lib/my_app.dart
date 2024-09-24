import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_finance/navigator.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    AppTheme.isDarkMode = brightness == Brightness.dark;
    return MaterialApp.router(
      title: 'MyFinance',
      theme: AppTheme.light(Colors.blue),
      darkTheme: AppTheme.dark(Colors.blue),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerDelegate: FinanceRouterDelegate(),
      routeInformationParser: FinanceRouteParser(),
    );
  }
}