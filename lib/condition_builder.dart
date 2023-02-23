import 'package:my_api/finance.dart';

class ConditionBuilder {

  static List<Map<String, dynamic>> currentMonthExpense(Currency currency) {
    final now = DateTime.now();
    return [{
      Transaction.keyType: TransactionType.expense.code,
      Transaction.keyPaidDate: [
        DateTime(now.year, now.month, 1, 0, 0, 0, 0).millisecondsSinceEpoch,
        DateTime(now.year, now.month+1, 1, 0, 0, 0, 0).millisecondsSinceEpoch,
      ],
      Transaction.keyCurrency: currency.value,
      Transaction.keyIncluded: true,
      FinanceModel.keyDeleted: false,
    }];
  }

  static List<Map<String, dynamic>> amountToBePaid(Currency currency) {
    final now = DateTime.now();
    return [{
      Transaction.keyType: TransactionType.expense.code,
      Transaction.keyCalculatedDate: [
        now.millisecondsSinceEpoch,
      ],
      Transaction.keyCurrency: currency.value,
      Transaction.keyIncluded: true,
      FinanceModel.keyDeleted: false,
    }];
  }

  static List<Map<String, dynamic>> budgets(Currency currency) {
    final now = DateTime.now();
    return [{
      Transaction.keyType: TransactionType.expense.code,
      Transaction.keyCurrency: currency.value,
      Transaction.keyIncluded: true,
      FinanceModel.keyDeleted: false,
      Transaction.keyPaidDate: {
        "max": DateTime(now.year, now.month+1, 0).millisecondsSinceEpoch,
      },
      Transaction.keyUtilityEnd: {
        "min": DateTime(now.year, now.month, 1).millisecondsSinceEpoch,
      }
    }];
  }

}