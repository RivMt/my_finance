import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_api/provider.dart' as provider;

final _dateBegin = DateTime.now();
final _dateEnd = DateTime(_dateBegin.year, _dateBegin.month + 2, 1);

final _expenseTransactions = Provider<StatefulData<Map<_DataType, Decimal>>>((ref) {
  StatefulDataState state = StatefulDataState.ready;
  final List<Transaction> list = ref.watch(provider.transactions)
      .where((item) {
    return !item.deleted
        && item.type == TransactionType.expense
        && item.calculatedDate.compareTo(_dateBegin) >= 0
        && item.calculatedDate.compareTo(_dateEnd) == -1;
  }).toList();
  if (list.isEmpty) {
    state = StatefulDataState.error(LocaleKeys.msgNoTransactions.tr());
  }
  final payments = ref.watch(provider.payments);
  if (payments.isEmpty) {
    state = StatefulDataState.error(LocaleKeys.msgNoPayment.tr());
  }
  Map<_DataType, Decimal> map = {};
  for(Transaction item in list) {
    final payment = payments.firstWhere((e) => e.uuid == item.paymentId, orElse: () => Payment.unknown);
    final key = _DataType(item.calculatedDate, payment);
    map[key] = (map[key] ?? Decimal.zero) + item.amount;
  }
  final entries = map.entries.toList();
  entries.sort((e1, e2) => e1.key.compareTo(e2.key));
  return StatefulData(Map.fromEntries(entries), state);
});

/// Summarizes upcoming expense withdrawals by date and payment.
class DueToPaidCard extends ConsumerStatefulWidget {
  const DueToPaidCard({
    super.key,
  });

  @override
  ConsumerState createState() => DueToPaidCardState();
}

/// State for [DueToPaidCard] with an externally callable refresh method.
class DueToPaidCardState extends ConsumerState<DueToPaidCard> {

  /// Appends upcoming expense transactions to the shared provider.
  void fetch() async {
    // Query by calculated withdrawal date.
    provider.appendTransactions(ref, {
      ModelKeys.keyDeleted: false,
      ModelKeys.keyType: TransactionType.expense.code,
      ModelKeys.keyCalculatedDate: {
        ApiQuery.keyQueryRangeBegin: _dateBegin.toIso8601String(),
        ApiQuery.keyQueryRangeEnd: _dateEnd.toIso8601String(),
      },
    });
  }

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  Widget build(BuildContext context) {
    final map = ref.watch(_expenseTransactions).data;
    final state = ref.watch(_expenseTransactions).state;
    return HomeCard(
      title: LocaleKeys.amountBePaid.tr(),
      state: state,
      children: [
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: map.length,
          itemBuilder: (context, index) {
            final item = map.entries.toList(growable: false)[index];
            final currency = provider.getCurrency(ref, item.key.payment.currencyId);
            return ListTile(
              title: Text(currency.format(item.value)),
              subtitle: Text(DateFormat(LocaleKeys.formatDateMd.tr()).format(item.key.date.toLocal())),
              leading: Tooltip(
                message: item.key.payment.descriptions,
                child: WalletItemIcon(
                  foreground: item.key.payment.foreground,
                  background: item.key.payment.background,
                  icon: item.key.payment.icon.icon,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Groups an upcoming amount by withdrawal date and payment.
class _DataType {

  _DataType(this.date, this.payment);

  /// Calculated withdrawal date.
  final DateTime date;

  /// Payment handler for the grouped transactions.
  final Payment payment;

  /// Orders groups by withdrawal date.
  int compareTo(_DataType other) {
    return (date.compareTo(other.date));
  }

  @override
  int get hashCode {
    return (date.year * 10000 + date.month * 100 + date.day) * 1000 + payment.uuid.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (other is _DataType) {
      return (date.year == other.date.year
      && date.month == other.date.month
      && date.day == other.date.day
      && payment == other.payment
      );
    }
    return super==other;
  }

}
