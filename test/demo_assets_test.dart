import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';

void main() {
  test('provides opaque colors for demo accounts and payments', () {
    final items = ['accounts', 'payments'].expand((asset) {
      return (json.decode(
        File('assets/demo/$asset').readAsStringSync(),
      ) as List)
          .map((item) => Map<String, dynamic>.from(item as Map));
    }).toList();

    for (final item in items) {
      for (final key in ['foreground', 'background']) {
        final color = item[key] as int;
        expect(color & 0xFF000000, 0xFF000000);
      }
    }
    expect(
      items.map((item) => item['background']).toSet(),
      hasLength(items.length),
    );
  });

  test('provides finance demo preferences', () {
    final preferences = (json.decode(
      File('assets/demo/preferences').readAsStringSync(),
    ) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final aligned = alignDemoTargetBalanceDates(
      preferences,
      now: DateTime(2027, 2, 10),
    );
    final values = {
      for (final item in aligned)
        item['pref_key']: Preference.decode(item['pref_value']),
    };

    expect(values[PreferenceKeys.defaultCurrency], 'USD');
    final targets = values[PreferenceKeys.targetBalance] as Map;
    final usdTargets = targets['USD'] as Map;
    expect(usdTargets.keys.single, '2027-02-28T00:00:00.000');
    expect(usdTargets.values.single, Decimal.parse('3000'));
  });

  test('aligns the transaction asset to a selected month', () {
    final transactions = (json.decode(
      File('assets/demo/transactions').readAsStringSync(),
    ) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final aligned = alignDemoTransactionDates(
      transactions,
      now: DateTime(2027, 2, 10),
    );

    for (final transaction in aligned) {
      final paidDate = DateTime.parse(transaction[ModelKeys.keyPaidDate]);
      final calculatedDate =
          DateTime.parse(transaction[ModelKeys.keyCalculatedDate]);
      expect((paidDate.year, paidDate.month), (2027, 2));
      expect((calculatedDate.year, calculatedDate.month), (2027, 2));
    }
  });
}
