import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/my_app.dart';

/// Initializes dependencies and starts the finance application.
void main() async {
  // Initialize framework services and the API client.
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  usePathUrlStrategy();
  final Map<String, dynamic> preferences =
      jsonDecode(await rootBundle.loadString("assets/key/config.json"));
  await ApiClient().init(
    preferences,
    demoEndpoints: const [
      Account.endpoint,
      Payment.endpoint,
      Transaction.endpoint,
      Category.endpoint,
      Currency.endpoint,
      Preference.endpoint,
    ],
    demoTransformers: {
      Transaction.endpoint: (items) => alignDemoTransactionDates(items),
      Preference.endpoint: (items) => alignDemoTargetBalanceDates(items),
    },
  );
  EasyLocalization.logger.printer = Log.easyLogger;

  // Start the localized Riverpod application.
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
