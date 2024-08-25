import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_finance/fragment/search_fragment.dart';

class SearchPage extends SearchDelegate {

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_outlined),
      onPressed: () => Navigator.pop(context),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.search_outlined),
        onPressed: () => showResults(context),
      ),
    ];
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 2) {
      return const MessageBox(
        icon: Icons.warning_amber_outlined,
        message: "",
      );
    }
    return buildResults(context);
  }

  @override
  Widget buildResults(BuildContext context) {
    final width = ScreenPlanner(context).panelWidth;
    final number = ScreenPlanner(context).panelNumber;
    return Align(
      alignment: number == 1 ? Alignment.topLeft : Alignment.topCenter,
      child: SizedBox(
        width: width,
        child: SearchFragment(
          query: query,
        ),
      ),
    );
  }
}