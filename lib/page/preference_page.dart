import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/fragment/budget_edit_fragment.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/preference_keys.dart';

class PreferencePage extends ConsumerStatefulWidget {

  static const String route = "/preferences";

  const PreferencePage({super.key});

  @override
  ConsumerState createState() => _PreferencePageState();
}

class _PreferencePageState extends ConsumerState<PreferencePage> {

  /// Value updating preferences are progressing or not
  bool _progressing = false;

  /// Value updating preferences are progressing or not
  ///
  /// This is wrapper of [_progressing]. When setting this, [setState] called
  /// automatically
  bool get progressing => _progressing;

  set progressing(bool value) {
    _progressing = value;
    setState(() {});
  }

  /// Request preferences from server
  void request() {
    ref.read(preferenceProvider.notifier).request();
  }

  /// Set [value] as [key] to [preferenceProvider]
  Future set(String key, dynamic value) async {
    progressing = true;
    await ref.read(preferenceProvider.notifier).set(Preference.fromKV(
      {},
      key: key,
      value: value,
    ));
    progressing = false;
    return;
  }

  /// Delete [key] from server
  Future delete(String key) async {
    progressing = true;
    await ref.read(preferenceProvider.notifier).delete(key);
    progressing = false;
    return;
  }

  /// Show currency selection dialog
  Future<Currency?> showCurrencySelectionDialog(BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (context) {
          final currencies = Currency.validValues;
          return AlertDialog(
            title: Text(LocaleKeys.object_action.tr(namedArgs: {
              "object": LocaleKeys.currency.plural(1),
              "action": LocaleKeys.select.tr(),
            })),
            content: SizedBox(
              width: ScreenPlanner(context).dialogWidth,
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
  }

  /// Show budget editing modal
  void showBudgetEditingModal(Currency currency, [Decimal? value]) {
    showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) {
        return Wrap(
          children: [
            BudgetEditFragment(
              base: value,
              currency: currency,
              onConfirmButtonPressed: (value) {
                final pref = ref.watch(preferenceProvider)[PreferenceKeys.budgets];
                if (pref != null) {
                  final map = pref.value;
                  map[currency.value] = value;
                  set(PreferenceKeys.budgets, map);
                }
                Navigator.pop(context);
              },
              onNegativeButtonPressed: () {
                final pref = ref.watch(preferenceProvider)[PreferenceKeys.budgets];
                // Check edit mode
                if (pref != null && value != null) {
                  final map = pref.value as Map;
                  map.remove(currency.value);
                  set(PreferenceKeys.budgets, map);
                }
                Navigator.pop(context);
              },
              onFinish: (value) {
                Navigator.pop(context, value);
              },
            ),
          ],
        );
      },
    ).then((value) {
      request();
    });
  }

  /// Triggers on default currency preference pressed
  void onDefaultCurrencyPressed(BuildContext context) async {
    final Currency? currency = await showCurrencySelectionDialog(context);
    if (currency == null) {
      return;
    }
    await set(PreferenceKeys.defaultCurrency, currency.value);
  }

  /// Triggers on budget add pressed
  void onBudgetAddButtonPressed(BuildContext context) async {
    final Currency? currency = await showCurrencySelectionDialog(context);
    // If no currency selected, escape
    if (currency == null) {
      return;
    }
    // Show modal
    showBudgetEditingModal(currency);
  }

  @override
  void initState() {
    super.initState();
    ref.read(preferenceProvider.notifier).setDefaults({
      PreferenceKeys.defaultCurrency: Currency.unknown,
      PreferenceKeys.budgets: {},
    });
    request();
  }

  @override
  void didUpdateWidget(PreferencePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    request();
  }

  @override
  Widget build(BuildContext context) {
    final width = ScreenPlanner(context).panelWidth;
    final Map<String, Preference> preferences = ref.watch(preferenceProvider);
    final budgets = preferences[PreferenceKeys.budgets]?.value ?? {};
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.settings.tr()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Visibility(
            visible: progressing,
            child: const LinearProgressIndicator(),
          ),
        ),
      ),
      body: SafeArea(
        child: Align(
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
                  // Budgets
                  PreferenceHeader(
                    title: LocaleKeys.budget.plural(1),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline_outlined),
                      color: Theme.of(context).primaryColor,
                      onPressed: () => onBudgetAddButtonPressed(context),
                    ),
                  ),
                  ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: budgets.keys.length,
                    itemBuilder: (context, index) {
                      final key = budgets.keys.toList(growable: false)[index];
                      final value = budgets[key];
                      final currency = Currency.fromValue(key);
                      return PreferenceTile(
                        title: currency.key.tr(),
                        subtitle: currency.format(value ?? Decimal.zero),
                        onTap: () => showBudgetEditingModal(currency, value),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}