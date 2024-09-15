import 'package:decimal/decimal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_api/provider.dart' as provider;

final _dateBegin = DateTime.now();
final _dateEnd = DateTime(_dateBegin.year, _dateBegin.month + 1, 1);

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
    state = StatefulDataState.loading;
  }
  final payments = ref.watch(provider.payments);
  if (payments.isEmpty) {
    state = StatefulDataState.error(LocaleKeys.msgNoPayment.tr());
  }
  Map<_DataType, Decimal> map = {};
  for(Transaction item in list) {
    final payment = payments.firstWhere((e) => e.pid == item.paymentId, orElse: () => Payment.unknown);
    final key = _DataType(item.calculatedDate, payment);
    map[key] = (map[key] ?? Decimal.zero) + item.amount;
  }
  final entries = map.entries.toList();
  entries.sort((e1, e2) => e1.key.compareTo(e2.key));
  return StatefulData(Map.fromEntries(entries), state);
});

class DueToPaidFragment extends ConsumerStatefulWidget {
  const DueToPaidFragment({
    super.key,
  });

  @override
  ConsumerState createState() => _DueToPaidFragmentState();
}

class _DueToPaidFragmentState extends ConsumerState<DueToPaidFragment> {

  /// Fetch transaction data
  void fetch() async {
    // Request
    provider.fetchTransactions(ref, [{
      ModelKeys.keyDeleted: false,
      ModelKeys.keyType: TransactionType.expense.code,
      ModelKeys.keyCalculatedDate: [
        _dateBegin.millisecondsSinceEpoch,
        _dateEnd.millisecondsSinceEpoch,
      ],
    }]);
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
          shrinkWrap: true,
          itemCount: map.length,
          itemBuilder: (context, index) {
            final item = map.entries.toList(growable: false)[index];
            return ListTile(
              title: Text(item.key.payment.currency.format(item.value)),
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

class _DataType {

  _DataType(this.date, this.payment);

  final DateTime date;

  final Payment payment;

  int compareTo(_DataType other) {
    return (date.compareTo(other.date));
  }

  @override
  int get hashCode {
    return (date.year * 10000 + date.month * 100 + date.day) * 1000 + payment.pid;
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