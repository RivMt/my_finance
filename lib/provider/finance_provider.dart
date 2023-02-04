import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';

class FinanceProvider {

  static final accounts = StateNotifierProvider<FinanceModelState<Account>, List<Account>>((ref) {
    return FinanceModelState<Account>(ref);
  });

  static final payments = StateNotifierProvider<FinanceModelState<Payment>, List<Payment>>((ref) {
    return FinanceModelState<Payment>(ref);
  });

  static final transactions = StateNotifierProvider<FinanceModelState<Transaction>, List<Transaction>>((ref) {
    return FinanceModelState<Transaction>(ref);
  });

  static final categories = StateNotifierProvider<FinanceModelState<Category>, List<Category>>((ref) {
    return FinanceModelState<Category>(ref);
  });

}