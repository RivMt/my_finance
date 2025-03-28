import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';

final selectedAccount = StateNotifierProvider<ModelState<String>, String>((ref) {
  return ModelState<String>(ref, "", Account.unknown.uuid);
});

final selectedPayment = StateNotifierProvider<ModelState<String>, String>((ref) {
  return ModelState<String>(ref, "", Payment.unknown.uuid);
});