import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/model/model_keys.dart';
import 'package:my_finance/model/transfer.dart';

void main() {
  group("Transfer", () {
    test("always initializes with the transfer-to category", () {
      final transfer = Transfer({
        ModelKeys.keyCategoryId: Category.transferFrom.uuid,
      });

      expect(transfer.categoryId, Category.transferTo.uuid);
      expect(
        transfer.map[ModelKeys.keyCategoryId],
        Category.transferTo.uuid,
      );
    });

    test("rejects changing its category", () {
      final transfer = Transfer.init();

      expect(
        () => transfer.categoryId = Category.transferFrom.uuid,
        throwsUnsupportedError,
      );
    });

    test("rejects changing every fixed field", () {
      final transfer = Transfer.init();

      expect(
        () => transfer.categoryId = Category.transferFrom.uuid,
        throwsUnsupportedError,
      );
      expect(
        () => transfer.paymentId = Payment.unknown.uuid,
        throwsUnsupportedError,
      );
      expect(
        () => transfer.type = TransactionType.income,
        throwsUnsupportedError,
      );
      expect(
        () => transfer.isIncluded = true,
        throwsUnsupportedError,
      );
    });

    test("serializes the destination account", () {
      final transfer = Transfer.init()..accountTo = "destination-account";

      expect(transfer.accountTo, "destination-account");
      expect(
        transfer.map[FinanceModelKeys.keyAccountTo],
        "destination-account",
      );
    });

    test("validates accounts, currencies, and amounts", () {
      final transfer = Transfer.init()
        ..accountId = "source"
        ..accountTo = "destination"
        ..currencyId = "USD"
        ..altCurrencyId = "USD"
        ..amount = Decimal.fromInt(10)
        ..altAmount = Decimal.fromInt(10);

      expect(transfer.isValid, true);

      transfer.accountTo = transfer.accountId;
      expect(transfer.isValid, false);
      transfer.accountTo = "destination";

      transfer.altAmount = Decimal.fromInt(11);
      expect(transfer.isValid, false);

      transfer.altCurrencyId = "JPY";
      expect(transfer.useAlt, true);
      expect(transfer.isValid, true);

      transfer.altCurrencyId = Currency.unknown.uuid;
      expect(transfer.isValid, false);
    });
  });
}
