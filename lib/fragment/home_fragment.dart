import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_finance/fragment/due_to_paid_fragment.dart';
import 'package:my_finance/fragment/expense_chart_fragment.dart';

class HomeFragment extends ConsumerStatefulWidget {

  const HomeFragment({super.key});

  @override
  ConsumerState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomeFragment> {

  final List<Widget> children = [
    const ExpenseChartFragment(),
    const DueToPaidFragment(),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: MasonryGridView.count(
        itemCount: children.length,
        crossAxisCount: ScreenPlanner(context).panelNumber,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        itemBuilder: (context, index) {
          return children[index];
        },
      ),
    );
  }
}