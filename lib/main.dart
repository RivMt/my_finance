import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_finance/my_app.dart';

void main() async {
  // Lazy
  WidgetsFlutterBinding.ensureInitialized();

  // Localizations
  await EasyLocalization.ensureInitialized();

  // Run
  runApp(ProviderScope(
    child: EasyLocalization(
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      path: 'assets/locale',
      fallbackLocale: const Locale('en', 'US'),
      child: const MyApp(),
    ),
  ));
}