import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/provider/finance_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {

  static const String _tag = "HomePage";

  final client = ApiClient();

  void openPage(Widget page, [Function(dynamic)? onPageFinished]) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page)).then((value) {
      if (onPageFinished != null) {
        onPageFinished(value);
      }
    });
  }

  /// Triggers on menu button pressed
  void onAccountIconPressed() {
    init();
  }

  /// Init API
  void init() async {
    try {
      await client.init(
        filename: 'assets/key/server.json',
        onLoginRequired: () => openPage(const LoginPage(), (value) => request()),
      );
    } on Exception catch(e) {
      Log.e(_tag, "Error: $e");
      return;
    }
  }

  /// Request data
  void request() async {
    ref.read(FinanceProvider.accounts.notifier).request(
      {
        Account.keyBalance: [
          "0.0",
        ],
      },
      ApiClient().buildOptions(
        limit: 3,
        sortOrderType: SortOrderType.asc,
        sortOrderAttribute: Account.keyPriority,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    request();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(FinanceProvider.accounts);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => request(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => onAccountIconPressed(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GroupCard(
              title: LocaleKeys.account.plural(1),
              count: accounts.length,
              build: (BuildContext context, int index) {
                return AccountCard(
                  data: accounts[index],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}