import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/my_api.dart';
import 'package:my_finance/generated/locale_keys.g.dart';
import 'package:my_finance/page/account_details_page.dart';
import 'package:my_finance/page/accounts_page.dart';
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
    // Account
    ref.read(FinanceProvider.accounts.notifier).request(
      {},
      ApiClient().buildOptions(
        limit: 3,
        sortOrderType: SortOrderType.asc,
        sortOrderAttribute: Account.keyPriority,
      ),
    );
    // Payment
    ref.read(FinanceProvider.payments.notifier).request(
      {},
      ApiClient().buildOptions(
        limit: 3,
        sortOrderType: SortOrderType.asc,
        sortOrderAttribute: Payment.keyPriority,
      ),
    );
  }

  /// Get [GridView] cross axis count
  ///
  /// Value is always bigger than `0`
  int getCrossAxisCount(BuildContext context) => InterfaceConstructor.panelNumber(context);

  /// Get [GridView] child aspect ratio
  double getChildAspectRatio(BuildContext context) {
    return (MediaQuery.of(context).size.width / getCrossAxisCount(context)) / GroupCard.height;
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
      body: GridView(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: getCrossAxisCount(context),
          childAspectRatio: getChildAspectRatio(context),
          mainAxisSpacing: 8,
        ),
        children: [
          GroupCard(
            title: LocaleKeys.account.plural(1),
            count: accounts.length,
            onMorePressed: () => openPage(const AccountsPage()),
            build: (BuildContext context, int index) {
              final account = accounts[index];
              return AccountCard(
                data: account,
                onTap: () => openPage(AccountDetailsPage(pid: account.pid)),
              );
            },
          ),
          GroupCard(
            title: LocaleKeys.payment.plural(1),
            count: 3,
            build: (BuildContext context, int index) {
              switch(index) {
                case 0:
                  return WalletItemCard(
                    title: Currency.won.format(ref.watch(FinanceProvider.expenses)),
                    subtitle: LocaleKeys.currentMonthExpense.tr(),
                    foreground: Colors.white,
                    background: Theme.of(context).primaryColor,
                    icon: Icons.payments_outlined,
                  );
                case 1:
                  return WalletItemCard(
                    title: Currency.won.format(ref.watch(FinanceProvider.expenses)),
                    subtitle: LocaleKeys.amountBePaid.tr(),
                    foreground: Colors.white,
                    background: Theme.of(context).primaryColor,
                    icon: Icons.calendar_today_outlined,
                  );
                default:
                  return const SizedBox();
              }
            },
          ),
        ],
      ),
    );
  }
}