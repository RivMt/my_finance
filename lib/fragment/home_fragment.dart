import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_finance/card/due_to_paid_card.dart';
import 'package:my_finance/card/expense_chart_card.dart';
import 'package:my_finance/card/target_balance_card.dart';

class HomeFragment extends ConsumerStatefulWidget {

  const HomeFragment({super.key});

  @override
  ConsumerState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomeFragment> {

  final GlobalKey<DueToPaidCardState> _dueToPaidKey = GlobalKey();

  final List<Widget> children = [
    const ExpenseChartCard(),
    const DueToPaidCard(),
    const TargetBalanceCard(),
  ];

  /// Triggers on scroll down
  Future<void> refresh() {
    _dueToPaidKey.currentState?.fetch();
    return Future<void>.value();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: Padding(
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
      ),
    );
  }
}