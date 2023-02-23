import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_finance/condition_builder.dart';
import 'package:my_finance/page/accounts_page.dart';
import 'package:my_finance/page/categories_page.dart';
import 'package:my_finance/page/home_page.dart';
import 'package:my_finance/page/payments_page.dart';
import 'package:my_finance/page/preference_page.dart';

List<RoutePath> _d1 = [
  FinanceRoutePath.accounts,
  FinanceRoutePath.payments,
  FinanceRoutePath.categories,
  FinanceRoutePath.preferences,
];

List<RoutePath> _d2 = [
  FinanceRoutePath.accounts,
  FinanceRoutePath.payments,
];

class FinanceRouteParser extends RouteParser {

  @override
  List<RoutePath> get d1 {
    List<RoutePath> value = super.d1;
    value.addAll(_d1);
    return value;
  }

  @override
  List<RoutePath> get d2 {
    List<RoutePath> value = super.d2;
    value.addAll(_d2);
    return value;
  }
}

class FinanceRoutePath extends RoutePath {

  static final FinanceRoutePath search = FinanceRoutePath("search");

  static final FinanceRoutePath accounts = FinanceRoutePath("accounts");

  static final FinanceRoutePath payments = FinanceRoutePath("payments");

  static final FinanceRoutePath categories = FinanceRoutePath("categories");

  static final FinanceRoutePath preferences = FinanceRoutePath("preferences");

  static const String keyMode = "mode";

  FinanceRoutePath(super.path);
}

class FinanceRouterDelegate extends CoreRouterDelegate {

  @override
  List<Page> findPage() {
    // Find page
    final pages = super.findPage();
    if (pages.isNotEmpty) {
      return pages;
    }
    late Widget? page;
    if (currentConfiguration.path == FinanceRoutePath.accounts.path) {
      // Accounts
      page = AccountsPage(
        router: this,
      );
    } else if (currentConfiguration.path == FinanceRoutePath.payments.path) {
      // Payments
      final currency = Currency.fromValue(currentConfiguration.queries![Payment.keyCurrency]);
      final mode = currentConfiguration.queries![FinanceRoutePath.keyMode] ?? "";
      late List<Map<String, dynamic>>? condition;
      if (mode == PaymentsPage.keyAmountToBePaid) {
        condition = ConditionBuilder.amountToBePaid(currency);
      } else if (mode == PaymentsPage.keyCurrentMonthExpense) {
        condition = ConditionBuilder.currentMonthExpense(currency);
      } else if (mode == PaymentsPage.keyBudgets) {
        condition = ConditionBuilder.budgets(currency);
      } else {
        condition = null;
      }
      page = PaymentsPage(
        subtitle: currentConfiguration.queries![FinanceModel.keyDescriptions] ?? "",
        currency: currency,
        condition: condition,
      );
    } else if (currentConfiguration.path == FinanceRoutePath.categories.path) {
      // Category
      page = const CategoriesPage();
    } else if (currentConfiguration.path == FinanceRoutePath.preferences.path) {
      // Preference
      page = const PreferencePage();
    } else {
      page = null;
    }
    if (page != null) {
      pages.add(MaterialPage(
        key: ValueKey(currentConfiguration.location),
        child: page,
      ));
    }
    return pages;
  }

  @override
  Widget get home => HomePage(
    router: this,
  );
}