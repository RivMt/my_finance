import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';

final selectedAccount = StateNotifierProvider<ModelState<int>, int>((ref) {
  return ModelState<int>(ref, Account.unknown.pid);
});

final selectedPayment = StateNotifierProvider<ModelState<int>, int>((ref) {
  return ModelState<int>(ref, Payment.unknown.pid);
});