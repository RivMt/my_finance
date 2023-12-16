import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';

final transactions = StateNotifierProvider<ModelsState<Transaction>, List<Transaction>>((ref) {
  return ModelsState<Transaction>(ref);
});

void refreshTransactions(WidgetRef ref, List<Map<String, dynamic>> condition) async {
  ref.read(transactions.notifier).request(
    condition,
    ApiClient.buildOptions(
      sorts: [
        const Sort(ModelKeys.keyPaidDate, SortType.desc),
      ],
    ),
  );
}