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
  Widget buildSuggestions(BuildContext context) => build(context);

  @override
  Widget buildResults(BuildContext context) => build(context);

  Widget build(BuildContext context) {
    final width = ScreenPlanner(context).panelWidth;
    final number = ScreenPlanner(context).panelNumber;
    return Align(
      alignment: number == 1 ? Alignment.topLeft : Alignment.topCenter,
      child: Container(
        width: width,
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: SearchFragment(
          query: query,
        ),
      ),
    );
  }
}