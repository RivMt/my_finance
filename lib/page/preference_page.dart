import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/dialog/currency_select_dialog.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/modal/target_balance_edit_modal.dart';

const String _tag = "PreferencePage";

final _pieChartMaxEntries = Provider<int>((ref) {
  final root = ref.watch(provider.financePreference);
  return root.get<int>(PreferenceKeys.pieChartMaxEntries, 5).value;
});

final _targetBalances = Provider<List<Map<String, dynamic>>>((ref) {
  final root = ref.watch(provider.financePreference);
  final targetBalances = <Map<String, dynamic>>[];
  root.get(PreferenceKeys.targetBalance, null).map.forEach((String uuid, map) {
    if (map is Map<String, dynamic>) {
      map.forEach((String date, amount) {
        try {
          targetBalances.add({
            ModelKeys.keyDate: DateTime.parse(date),
            ModelKeys.keyCurrencyId: uuid,
            ModelKeys.keyAmount: amount,
          });
        } on FormatException {
          Log.e(_tag, "Unable to parse target balance item: $date, $uuid, $amount");
        }
      });
    }
  });
  return targetBalances;
});

/// Edits finance preferences and target balances.
class PreferencePage extends ConsumerStatefulWidget {

  /// Legacy route name for finance preferences.
  static const String route = "/preferences";

  const PreferencePage({super.key});

  @override
  ConsumerState createState() => _PreferencePageState();
}

class _PreferencePageState extends ConsumerState<PreferencePage> {

  /// Whether a preference update is in progress.
  bool _progressing = false;

  /// Whether a preference update is in progress.
  bool get progressing => _progressing;

  set progressing(bool value) {
    _progressing = value;
    setState(() {});
  }

  /// Shows the currency selection dialog.
  Future<Currency?> showCurrencySelectionDialog(BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (context) => const CurrencySelectDialog(),
    );
  }

  /// Shows the pie-chart entry limit editor.
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
              value: ref.watch(_pieChartMaxEntries).toDouble(),
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

  /// Updates the maximum number of pie-chart entries.
  void setPieChartMaxEntries(int value) {
    final root = ref.watch(provider.financePreference);
    root.set<int>(PreferenceKeys.pieChartMaxEntries, value);
    setPreference(ref, provider.financePreference, root);
  }

  /// Stores a target balance for [date] and [currency].
  void setTargetBalance(DateTime date, Currency currency, Decimal amount) {
    final root = ref.watch(provider.financePreference);
    final target = root.get(PreferenceKeys.targetBalance, null).get(currency.uuid, null);
    target.set<Decimal>(date.toIso8601String(), amount);
    setPreference(ref, provider.financePreference, root);
  }

  /// Removes the target balance for [date] and [currency].
  void removeTargetBalance(DateTime date, Currency currency) {
    final root = ref.watch(provider.financePreference);
    final targets = root.get(PreferenceKeys.targetBalance, null).get(currency.uuid, null);
    final result = targets.remove(date.toIso8601String());
    if (result == null) {
      Log.w(_tag, "No target balance about '${date.toIso8601String()}' -> '${currency.uuid}'");
      return;
    }
    setPreference(ref, provider.financePreference, root);
  }

  /// Shows a constrained bottom-sheet [child].
  void showModal({required Widget child}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: ScreenPlanner(context).panelWidth,
      ),
      builder: (context) => child,
    );
  }

  /// Selects the default currency.
  void onDefaultCurrencyPressed(BuildContext context) async {
    final Currency? currency = await showCurrencySelectionDialog(context);
    if (currency == null) {
      return;
    }
    provider.setDefaultCurrency(ref, currency);
  }

  /// Edits the pie-chart entry limit.
  void onPieChartMaxEntriesPressed(BuildContext context) async {
    final double? value = await showPieChartMaxEntriesInputModal(context);
    if (value == null) {
      return;
    }
    setPieChartMaxEntries(value.toInt());
  }

  /// Opens the target-balance creation or editing modal.
  void addOrEditTargetBalance({
    required BuildContext context,
    DateTime? date,
    Currency? currency,
    Decimal? amount,
  }) async {
    // Configure callbacks for create, update, and remove actions.
    showModal(
      child: TargetBalanceEditModal(
        date: date,
        currency: currency,
        amount: amount,
        onConfirmButtonPressed: (date, currency, amount) {
          setTargetBalance(date, currency, amount);
          Navigator.pop(context);
        },
        onNegativeButtonPressed: () {
          // Only existing targets can be removed.
          if (date != null && currency != null) {
            removeTargetBalance(date, currency);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = ScreenPlanner(context).panelWidth;
    final defaultCurrency = ref.watch(provider.defaultCurrency);
    final targetBalances = ref.watch(_targetBalances);
    final pieChartMaxEntries = ref.watch(_pieChartMaxEntries);
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
                  // General finance preferences.
                  PreferenceHeader(
                    title: LocaleKeys.preferenceGeneral.tr(),
                  ),
                  PreferenceTile(
                    title: LocaleKeys.preferenceDefaultCurrency.tr(),
                    subtitle: defaultCurrency.key.tr(),
                    onTap: () => onDefaultCurrencyPressed(context),
                  ),
                  PreferenceTile(
                    title: LocaleKeys.preferencePieChartMaxEntries.tr(),
                    subtitle: pieChartMaxEntries.toString(),
                    onTap: () => onPieChartMaxEntriesPressed(context),
                  ),
                  // Target balances by date and currency.
                  PreferenceHeader(
                    title: LocaleKeys.targetBalance.tr(),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline_outlined),
                      color: Theme.of(context).primaryColor,
                      onPressed: () => addOrEditTargetBalance(context: context),
                    ),
                  ),
                  ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: targetBalances.length,
                    itemBuilder: (context, index) {
                      final target = targetBalances[index];
                      final date = target[ModelKeys.keyDate];
                      final amount = target[ModelKeys.keyAmount];
                      final uuid = target[ModelKeys.keyCurrencyId];
                      if (date == null || amount == null || uuid == null) {
                        return const SizedBox();
                      }
                      final currency = provider.getCurrency(ref, uuid);
                      return PreferenceTile(
                        title: currency.key.tr(),
                        subtitle: currency.format(amount ?? Decimal.zero),
                        trailing: Text(LocaleKeys.nToDate.tr(args: [DateFormat.yMd().format(date)])),
                        onTap: () => addOrEditTargetBalance(
                          context: context,
                          date: date,
                          currency: currency,
                          amount: amount,
                        ),
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
