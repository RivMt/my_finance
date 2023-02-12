import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/preference_keys.dart';

class PreferencePage extends ConsumerStatefulWidget {
  const PreferencePage({super.key});

  @override
  _PreferencePageState createState() => _PreferencePageState();
}

class _PreferencePageState extends ConsumerState<PreferencePage> {

  /// Request preferences from server
  void request() {
    ref.read(preferenceProvider.notifier).request();
  }

  @override
  void initState() {
    super.initState();
    ref.read(preferenceProvider.notifier).setDefaults({
      PreferenceKeys.defaultCurrency: Currency.unknown,
    });
    request();
  }

  @override
  void didUpdateWidget(PreferencePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  /// Triggers on default currency preference pressed
  void onDefaultCurrencyPressed(BuildContext context) async {
    final Currency currency = await showDialog(
      context: context,
      builder: (context) {
        final currencies = Currency.validValues;
        return AlertDialog(
          title: Text(LocaleKeys.object_action.tr(namedArgs: {
            "object": LocaleKeys.currency.plural(1),
            "action": LocaleKeys.select.tr(),
          })),
          content: SizedBox(
            width: MediaQuery.of(context).size.width / InterfaceConstructor.panelNumber(context),
            child: ListView.builder(
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                return CurrencyCard(
                  data: currencies[index],
                  useIconBackground: false,
                  onTap: () => Navigator.pop(context, currencies[index]),
                );
              },
            ),
          ),
        );
      }
    );
    ref.read(preferenceProvider.notifier).set(Preference.fromKV(
      {},
      key: PreferenceKeys.defaultCurrency,
      value: currency.value,
    ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width / InterfaceConstructor.panelNumber(context);
    final Map<String, Preference> preferences = ref.watch(preferenceProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.settings.tr()),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // General
                PreferenceHeader(
                  title: LocaleKeys.preferenceGeneral.tr(),
                ),
                PreferenceTile(
                  title: LocaleKeys.preferenceDefaultCurrency.tr(),
                  subtitle: Currency.fromValue(preferences[PreferenceKeys.defaultCurrency]?.value).key.tr(),
                  onTap: () => onDefaultCurrencyPressed(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}