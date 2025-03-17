import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_finance/my_app.dart';

void main() async {
  // Init
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  usePathUrlStrategy();
  final preferences = jsonDecode(await rootBundle.loadString("assets/key/server.json"));

  // Run
  runApp(ProviderScope(
    child: EasyLocalization(
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      path: 'assets/locale',
      fallbackLocale: const Locale('en', 'US'),
      child: MyApp(preferences: preferences),
    ),
  ));
}