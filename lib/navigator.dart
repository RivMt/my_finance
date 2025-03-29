import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_finance/page/account_details_page.dart';
import 'package:my_finance/page/categories_page.dart';
import 'package:my_finance/page/home_page.dart';
import 'package:my_finance/page/payment_details_page.dart';
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

  FinanceRoutePath(super.path, [super.pid, super.queries, super.anchor]);
}

class FinanceRouterDelegate extends CoreRouterDelegate {

  /// Find page by [currentConfiguration] value
  Widget? getPage() {
    if (currentConfiguration.path == FinanceRoutePath.accounts.path) {
      // Accounts
      final pid = currentConfiguration.uuid;
      if (pid != null) {
        return const AccountDetailsPage();
      }
    } else if (currentConfiguration.path == FinanceRoutePath.payments.path) {
      // Payments
      final pid = currentConfiguration.uuid;
      if (pid != null) {
        return const PaymentDetailsPage();
      }
    } else if (currentConfiguration.path == FinanceRoutePath.categories.path) {
      // Category
      return const CategoriesPage();
    } else if (currentConfiguration.path == FinanceRoutePath.preferences.path) {
      // Preference
      return null;//const PreferencePage();
    }
    return null;
  }

  @override
  List<Page> findPage() {
    // Find page
    final pages = super.findPage();
    if (pages.isNotEmpty) {
      return pages;
    }
    final page = getPage();
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