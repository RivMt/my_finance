import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';

const String _tag = "FinanceProvider";

class FinanceProvider {

  static final accounts = StateNotifierProvider<AccountState, List<Account>>((ref) {
    return AccountState(ref);
  });

}

class AccountState extends StateNotifier<List<Account>> {

  AccountState(this.ref) : super([]);

  final Ref ref;

  void request(Map<String, dynamic> condition, [Map<String, dynamic>? options]) async {
    final client = ApiClient();
    final ApiResponse<List<Account>> response = await client.read<Account>(
      condition,
      options,
    );
    if (response.result != ApiResultCode.success) {
      Log.e(_tag, "Failed to request $condition");
      state = [];
      return;
    }
    state = response.data;
  }

}