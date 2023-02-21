import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_finance/fragment/search_results_fragment.dart';

class SearchFragment extends SearchDelegate {

  String text = "";

  @override
  void showResults(BuildContext context) {
    text = query;
    super.showResults(context);
  }

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
    return const Text("Message");
  }

  @override
  Widget buildResults(BuildContext context) {
    final width = ScreenPlanner(context).panelWidth;
    final number = ScreenPlanner(context).panelNumber;
    return Align(
      alignment: number == 1 ? Alignment.topLeft : Alignment.topCenter,
      child: SizedBox(
        width: width,
        child: SearchResultsFragment(
          query: text,
        ),
      ),
    );
  }
}