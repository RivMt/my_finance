import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_finance/my_app.dart';

void main() async {
  // Init
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  usePathUrlStrategy();
  final Map<String, dynamic> preferences = jsonDecode(await rootBundle.loadString("assets/key/config.json"));
  await ApiClient().init(preferences);
  EasyLocalization.logger.printer = Log.easyLogger;

  // Run
  runApp(ProviderScope(
    child: EasyLocalization(
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
        Locale('ja', 'JP')
      ],
      path: 'assets/locale',
      fallbackLocale: const Locale('en', 'US'),
      child: const MyApp(),
    ),
  ));
}