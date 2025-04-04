import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_finance/page/account_details_page.dart';
import 'package:my_finance/page/categories_page.dart';
import 'package:my_finance/page/home_page.dart';
import 'package:my_finance/page/payment_details_page.dart';
import 'package:my_finance/page/preference_page.dart';

const String _tag = "Navigator";

class FinanceRoutePath extends RoutePath {

  static final FinanceRoutePath search = FinanceRoutePath("search");

  static final FinanceRoutePath accounts = FinanceRoutePath("accounts", index: 1);

  static final FinanceRoutePath payments = FinanceRoutePath("payments", index: 2);

  static final FinanceRoutePath categories = FinanceRoutePath("categories");

  static final FinanceRoutePath preferences = FinanceRoutePath("preferences");

  static const String keyMode = "mode";

  FinanceRoutePath(super.path, {
    super.uuid,
    super.queries,
    super.anchor,
    super.index,
  });
}

class FinanceRouteParser extends RouteParser {

  @override
  List<RoutePath> get pathStandalone => [
    ...super.pathStandalone,
    FinanceRoutePath.categories,
    FinanceRoutePath.preferences,
  ];

  @override
  List<RoutePath> get pathDetails => [
    ...super.pathDetails,
    FinanceRoutePath.accounts,
    FinanceRoutePath.payments,
  ];

  @override
  List<RoutePath> get pathIndex => [
    ...super.pathIndex,
    FinanceRoutePath.accounts,
    FinanceRoutePath.payments,
  ];
}

class FinanceRouterDelegate extends CoreRouterDelegate {

  /// Home page index
  int _navigationRailIndex = 0;

  /// Set home page index
  void _setNavigationRailIndex(int index) {
    _navigationRailIndex = index;
    Log.v(_tag, "Change navigation rail index to $index");
    notifyListeners();
  }

  /// Find page by [configuration] value
  Widget? getPage(RoutePath configuration) {
    if (configuration.path == FinanceRoutePath.accounts.path) {
      // Accounts
      final uuid = configuration.uuid;
      if (uuid != null) {
        return const AccountDetailsPage();
      }
      _navigationRailIndex = configuration.index;
      return null;
    } else if (configuration.path == FinanceRoutePath.payments.path) {
      // Payments
      final uuid = configuration.uuid;
      if (uuid != null) {
        return const PaymentDetailsPage();
      }
      _navigationRailIndex = configuration.index;
      return null;
    } else if (configuration.path == FinanceRoutePath.categories.path) {
      // Category
      return const CategoriesPage();
    } else if (configuration.path == FinanceRoutePath.preferences.path) {
      // Preference
      return const PreferencePage();
    }
    _navigationRailIndex = configuration.index;
    return home;
  }

  @override
  List<Page> get pages {
    final pages = <Page>[];
    RoutePath configuration = currentConfiguration;
    do {
      final page = getPage(configuration);
      if (page != null) {
        pages.add(MaterialPage(
          key: ValueKey(configuration.uri),
          child: page,
        ));
      }
      final prev = configuration.previous();
      if (prev == configuration) {
        break;
      }
      configuration = prev;
    } while(true);
    return pages.reversed.toList(growable: false);
  }

  @override
  Future<void> setNewRoutePath(RoutePath configuration) async {
    if (_navigationRailIndex != configuration.index) {
      Log.v(_tag, "Change navigation index only: ${configuration.index}");
      _navigationRailIndex = configuration.index;
    }
    super.setNewRoutePath(configuration);
    return;
  }

  @override
  Widget get home => HomePage(
    router: this,
    index: _navigationRailIndex,
    onIndexChanged: _setNavigationRailIndex,
  );


}