import 'package:decimal/decimal.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/model/model_keys.dart';

/// A transfer from one account to another.
class Transfer extends Transaction {
  /// Path of the transfer API endpoint.
  static const String endpoint = "api/finance/transfer";

  /// Initializes a transfer from a serialized map.
  Transfer([super.map]) {
    _initializeTransferFields();
  }

  /// Initializes a new transfer.
  Transfer.init() : super.init() {
    _initializeTransferFields();
  }

  void _initializeTransferFields() {
    super.categoryId = Category.transferTo.uuid;
    super.paymentId = Payment.none.uuid;
    super.type = TransactionType.expense;
    super.isIncluded = false;
  }

  /// The destination account UUID.
  String get accountTo =>
      getString(FinanceModelKeys.keyAccountTo, BaseModel.unknownUuid);

  set accountTo(String uuid) => setString(FinanceModelKeys.keyAccountTo, uuid);

  /// Whether the source and destination accounts use different currencies.
  bool get useAlt => currencyId != altCurrencyId;

  @override
  bool get isValid {
    if (accountId == Account.unknown.uuid ||
        accountTo == Account.unknown.uuid ||
        accountId == accountTo) {
      return false;
    }
    if (currencyId == Currency.unknown.uuid ||
        altCurrencyId == Currency.unknown.uuid) {
      return false;
    }
    if (amount <= Decimal.zero || altAmount <= Decimal.zero) {
      return false;
    }
    if (!useAlt && amount != altAmount) {
      return false;
    }
    return super.isValid;
  }

  @override
  String get categoryId => Category.transferTo.uuid;

  @override
  set categoryId(String value) {
    throw UnsupportedError("A transfer category cannot be changed.");
  }

  @override
  set paymentId(String value) {
    throw UnsupportedError("A transfer payment cannot be changed.");
  }

  @override
  set type(TransactionType value) {
    throw UnsupportedError("A transfer type cannot be changed.");
  }

  @override
  set isIncluded(bool value) {
    throw UnsupportedError(
      "A transfer statistics-inclusion setting cannot be changed.",
    );
  }
}
