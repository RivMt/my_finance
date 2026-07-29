import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_finance/page/account_details_page.dart';
import 'package:my_finance/page/categories_page.dart';
import 'package:my_finance/page/advanced_query_page.dart';
import 'package:my_finance/page/home_page.dart';
import 'package:my_finance/page/payment_details_page.dart';
import 'package:my_finance/page/preference_page.dart';
import 'package:my_finance/page/read_csv_page.dart';
import 'package:my_finance/page/restore_items_page.dart';

const String _tag = "Navigator";

/// Defines route paths used by the finance application.
class FinanceRoutePath extends RoutePath {

  /// Accounts tab and account detail route.
  static final FinanceRoutePath accounts = FinanceRoutePath("accounts", index: 1);

  /// Payments tab and payment detail route.
  static final FinanceRoutePath payments = FinanceRoutePath("payments", index: 2);

  /// Category management route.
  static final FinanceRoutePath categories = FinanceRoutePath("categories");

  /// Deleted-item restoration route.
  static final FinanceRoutePath restores = FinanceRoutePath("restores");

  /// Advanced transaction query route.
  static final FinanceRoutePath advancedQuery = FinanceRoutePath("advanced_query");

  /// CSV import route.
  static final FinanceRoutePath readCsv = FinanceRoutePath("read_csv");

  /// Finance preferences route.
  static final FinanceRoutePath preferences = FinanceRoutePath("preferences");

  /// Search route.
  static final FinanceRoutePath search = FinanceRoutePath("search");

  /// Query key for a route mode.
  static const String keyMode = "mode";

  FinanceRoutePath(super.path, {
    super.uuid,
    super.queries,
    super.anchor,
    super.index,
  });
}

/// Parses finance routes into [FinanceRoutePath] values.
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

/// Builds the page stack for the current finance route.
class FinanceRouterDelegate extends CoreRouterDelegate {

  /// Selected home-page destination index.
  int _navigationRailIndex = 0;

  /// Updates the selected home-page destination.
  void _setNavigationRailIndex(int index) {
    _navigationRailIndex = index;
    Log.v(_tag, "Change navigation rail index to $index");
    notifyListeners();
  }

  /// Returns the page represented by [configuration].
  Widget? getPage(RoutePath configuration) {
    if (configuration.path == FinanceRoutePath.accounts.path) {
      // Resolve the accounts tab or an account detail page.
      final uuid = configuration.uuid;
      if (uuid != null) {
        return AccountDetailsPage(uuid: uuid);
      }
      _navigationRailIndex = configuration.index;
      return null;
    } else if (configuration.path == FinanceRoutePath.payments.path) {
      // Resolve the payments tab or a payment detail page.
      final uuid = configuration.uuid;
      if (uuid != null) {
        return PaymentDetailsPage(uuid: uuid);
      }
      _navigationRailIndex = configuration.index;
      return null;
    } else if (configuration.path == FinanceRoutePath.categories.path) {
      return const CategoriesPage();
    } else if (configuration.path == FinanceRoutePath.restores.path) {
      return const RestoreItemsPage();
    } else if (configuration.path == FinanceRoutePath.advancedQuery.path) {
      return const AdvancedQueryPage();
    } else if (configuration.path == FinanceRoutePath.readCsv.path) {
      return const ReadCsvPage();
    } else if (configuration.path == FinanceRoutePath.preferences.path) {
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
