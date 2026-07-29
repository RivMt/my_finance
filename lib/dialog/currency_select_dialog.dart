import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/generated/locale_keys.g.dart';

/// Selects a [Currency] from the currencies provided by `my_api`.
class CurrencySelectDialog extends ConsumerWidget {

  const CurrencySelectDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencies = ref.watch(provider.currencies);
    return AlertDialog(
      title: Text(LocaleKeys.msgPleaseSelect_object.tr(namedArgs: {
        "object": LocaleKeys.currency.plural(1),
      })),
      content: SizedBox(
        width: ScreenPlanner(context).dialogWidth,
        child: ListView.builder(
          itemCount: currencies.length,
          itemBuilder: (context, index) {
            return CurrencyCard(
              currency: currencies[index],
              useIconBackground: false,
              onTap: () => Navigator.pop(context, currencies[index]),
            );
          },
        ),
      ),
    );
  }
}
