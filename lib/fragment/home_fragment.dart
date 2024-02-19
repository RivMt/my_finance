import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_finance/fragment/expense_chart_fragment.dart';

class HomeFragment extends ConsumerStatefulWidget {

  const HomeFragment({super.key});

  @override
  ConsumerState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomeFragment> {

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: ExpenseChartFragment(),
            ),
          ),
        ],
      ),
    );
  }
}