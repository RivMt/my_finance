import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/dialog/currency_select_dialog.dart';
import 'package:my_finance/modal/budget_edit_modal.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/modal/target_balance_edit_modal.dart';

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

  /// Set [value] as [key] to [provider.preferences]
  Future set(String key, dynamic value) async {
    progressing = true;
    await provider.setPreference(ref, key, value);
    progressing = false;
    return;
  }

  /// Delete [key] from server
  Future delete(String key) async {
    progressing = true;
    await ref.read(provider.preferences.notifier).delete(key);
    progressing = false;
    return;
  }

  /// Show currency selection dialog
  Future<Currency?> showCurrencySelectionDialog(BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (context) => const CurrencySelectDialog(),
    );
  }

  /// Show currency selection dialog
  Future<double?> showPieChartMaxEntriesInputModal(BuildContext context) async {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) {
        return Wrap(
          children: [
            ValueEditModal(
              title: LocaleKeys.preferencePieChartMaxEntries.tr(),
              value: (provider.getPreference<int>(ref, PreferenceKeys.pieChartMaxEntries) ?? 5).toDouble(),
              tick: 1.0,
              isDecimal: true,
              positiveButtonTitle: LocaleKeys.confirm.tr(),
              negativeButtonTitle: LocaleKeys.cancel.tr(),
            ),
          ],
        );
      }
    );
  }

  /// Show modal
  void showModal({required Widget child}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) => child,
    ).then((value) {
      provider.syncPreferences(ref);
    });
  }

  /// Triggers on default currency preference pressed
  void onDefaultCurrencyPressed(BuildContext context) async {
    final Currency? currency = await showCurrencySelectionDialog(context);
    if (currency == null) {
      return;
    }
    await set(PreferenceKeys.defaultCurrency, currency.uuid);
  }

  /// Triggers on default currency preference pressed
  void onPieChartMaxEntriesPressed(BuildContext context) async {
    final double? value = await showPieChartMaxEntriesInputModal(context);
    if (value == null) {
      return;
    }
    await set(PreferenceKeys.pieChartMaxEntries, value.toInt());
  }

  /// Triggers on budget add pressed
  void addOrEditBudget(BuildContext context, String key, [
    String currencyId = Currency.unknownUuid,
    Decimal? amount,
  ]) async {
    // Show modal
    showModal(
      child: BudgetEditModal(
        value: amount,
        currencyId: currencyId,
        onConfirmButtonPressed: (uuid, value) {
          final pref = ref.watch(provider.preferences)[key];
          // Update
          if (pref != null) {
            final Map map = pref.value;
            // Remove old
            if (currencyId != Currency.unknownUuid) {
              map.remove(currencyId);
              set(key, map);
            }
            map[uuid] = value;
            set(key, map);
          }
          Navigator.pop(context);
        },
        onNegativeButtonPressed: () {
          final pref = ref.watch(provider.preferences)[key];
          // Check edit mode
          if (pref != null && amount != null) {
            final map = pref.value as Map;
            map.remove(currencyId);
            set(key, map);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Triggers on target balance add pressed
  void addOrEditTargetBalance(BuildContext context, String key, [
    DateTime? date,
    String currencyId = Currency.unknownUuid,
    Decimal? amount,
  ]) async {
    // Show modal
    showModal(
      child: TargetBalanceEditModal(
        date: date,
        currencyId: currencyId,
        value: amount,
        onConfirmButtonPressed: (date, uuid, value) {
          final pref = ref.watch(provider.preferences)[key];
          // Update
          if (pref != null) {
            final Map map = pref.value;
            // Remove old
            if (currencyId != Currency.unknownUuid) {
              map.remove(currencyId);
              set(key, map);
            }
            map[uuid] = {
              ModelKeys.keyDate: date,
              ModelKeys.keyAmount: value,
            };
            set(key, map);
          }
          Navigator.pop(context);
        },
        onNegativeButtonPressed: () {
          final pref = ref.watch(provider.preferences)[key];
          // Check edit mode
          if (pref != null && amount != null) {
            final map = pref.value as Map;
            map.remove(currencyId);
            set(key, map);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = ScreenPlanner(context).panelWidth;
    final budgets = provider.getPreference(ref, PreferenceKeys.budgets);
    final targetBalances = provider.getPreference(ref, PreferenceKeys.targetBalance);
    final pieChartMaxEntries = provider.getPreference(ref, PreferenceKeys.pieChartMaxEntries);
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
                    subtitle: provider.getDefaultCurrency(ref).key.tr(),
                    onTap: () => onDefaultCurrencyPressed(context),
                  ),
                  PreferenceTile(
                    title: LocaleKeys.preferencePieChartMaxEntries.tr(),
                    subtitle: pieChartMaxEntries.toString(),
                    onTap: () => onPieChartMaxEntriesPressed(context),
                  ),
                  // Budgets
                  PreferenceHeader(
                    title: LocaleKeys.budget.plural(1),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline_outlined),
                      color: Theme.of(context).primaryColor,
                      onPressed: () => addOrEditBudget(context, PreferenceKeys.budgets),
                    ),
                  ),
                  ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: budgets.keys.length,
                    itemBuilder: (context, index) {
                      final uuid = budgets.keys.toList(growable: false)[index];
                      final value = budgets[uuid];
                      final currency = provider.getCurrency(ref, uuid);
                      return PreferenceTile(
                        title: currency.key.tr(),
                        subtitle: currency.format(value ?? Decimal.zero),
                        onTap: () => addOrEditBudget(context, PreferenceKeys.budgets, uuid, value),
                      );
                    },
                  ),
                  // Target balance
                  // Budgets
                  PreferenceHeader(
                    title: LocaleKeys.targetBalance.tr(),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline_outlined),
                      color: Theme.of(context).primaryColor,
                      onPressed: () => addOrEditTargetBalance(context, PreferenceKeys.targetBalance),
                    ),
                  ),
                  ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: targetBalances.keys.length,
                    itemBuilder: (context, index) {
                      final uuid = targetBalances.keys.toList(growable: false)[index];
                      final target = targetBalances[uuid] ?? {};
                      final date = target[ModelKeys.keyDate] ?? DateTime.now();
                      final value = target[ModelKeys.keyAmount];
                      final currency = provider.getCurrency(ref, uuid);
                      return PreferenceTile(
                        title: currency.key.tr(),
                        subtitle: currency.format(value ?? Decimal.zero),
                        trailing: Text(LocaleKeys.nToDate.tr(args: [DateFormat.yMd().format(date)])),
                        onTap: () => addOrEditTargetBalance(context, PreferenceKeys.targetBalance, date, uuid, value),
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