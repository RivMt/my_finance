import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';
import 'package:my_api/provider.dart' as provider;
import 'package:my_finance/card/due_to_paid_card.dart';
import 'package:my_finance/card/expense_chart_card.dart';
import 'package:my_finance/card/target_balance_card.dart';

/// Displays the finance summary cards in a responsive grid.
class HomeFragment extends ConsumerStatefulWidget {
  const HomeFragment({super.key});

  @override
  ConsumerState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomeFragment>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 450);

  final GlobalKey<DueToPaidCardState> _dueToPaidKey = GlobalKey();
  final GlobalKey _homeAreaKey = GlobalKey();
  final GlobalKey _expenseCardKey = GlobalKey();

  late DateTime _expenseMonth;
  late final AnimationController _expenseAnimationController;

  bool _isExpenseExpanded = false;
  bool _showExpenseOverlay = false;
  Rect? _collapsedExpenseRect;

  Future<void> _fetchExpenseTransactions(DateTime month) {
    final begin = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return provider.appendTransactions(ref, {
      ModelKeys.keyDeleted: false,
      ModelKeys.keyType: TransactionType.expense.code,
      ModelKeys.keyPaidDate: {
        ApiQuery.keyQueryRangeBegin: begin.toIso8601String(),
        ApiQuery.keyQueryRangeEnd: end.toIso8601String(),
      },
    });
  }

  void _expandExpense() {
    final homeBox =
        _homeAreaKey.currentContext?.findRenderObject() as RenderBox?;
    final cardBox =
        _expenseCardKey.currentContext?.findRenderObject() as RenderBox?;
    if (homeBox == null || cardBox == null) {
      return;
    }
    final cardOffset = cardBox.localToGlobal(
      Offset.zero,
      ancestor: homeBox,
    );
    setState(() {
      _collapsedExpenseRect = cardOffset & cardBox.size;
      _isExpenseExpanded = true;
      _showExpenseOverlay = true;
    });
    _expenseAnimationController.forward(from: 0);
  }

  Future<void> _collapseExpense() async {
    await _expenseAnimationController.reverse();
    if (!mounted) {
      return;
    }
    setState(() {
      _isExpenseExpanded = false;
      _showExpenseOverlay = false;
    });
  }

  void _onExpenseMonthChanged(DateTime month) {
    setState(() {
      _expenseMonth = month;
    });
    _fetchExpenseTransactions(month);
  }

  /// Refreshes summary data after a pull gesture.
  Future<void> refresh() {
    if (_isExpenseExpanded) {
      return _fetchExpenseTransactions(_expenseMonth);
    }
    _dueToPaidKey.currentState?.fetch();
    return Future<void>.value();
  }

  Widget _buildSummary(BuildContext context) {
    final children = [
      ExpenseChartCard(
        key: _expenseCardKey,
        onOpenPressed: _expandExpense,
      ),
      DueToPaidCard(key: _dueToPaidKey),
      const TargetBalanceCard(),
    ];
    return RefreshIndicator(
      key: const ValueKey('summary'),
      onRefresh: refresh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: MasonryGridView.count(
          itemCount: children.length,
          crossAxisCount: ScreenPlanner(context).panelNumber,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          itemBuilder: (context, index) => children[index],
        ),
      ),
    );
  }

  Widget _buildExpanded(double minHeight, double contentProgress) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: ExpenseChartCard(
            date: _expenseMonth,
            isExpanded: true,
            expansionProgress: contentProgress,
            onDateChanged: _onExpenseMonthChanged,
            onClosePressed: _collapseExpense,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _expenseMonth = DateTime(now.year, now.month, 1);
    _expenseAnimationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
      reverseDuration: _animationDuration,
    );
  }

  @override
  void dispose() {
    _expenseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      key: _homeAreaKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final expandedWidth =
              constraints.maxWidth > 16 ? constraints.maxWidth - 16 : 0.0;
          final expandedRect = Rect.fromLTWH(
            8,
            0,
            expandedWidth,
            constraints.maxHeight,
          );
          return AnimatedBuilder(
            animation: _expenseAnimationController,
            child: _buildSummary(context),
            builder: (context, summary) {
              final progress = Curves.easeInOutCubic.transform(
                _expenseAnimationController.value,
              );
              final cardRect = Rect.lerp(
                _collapsedExpenseRect ?? expandedRect,
                expandedRect,
                progress,
              )!;
              final contentProgress = const Interval(
                0.2,
                0.75,
                curve: Curves.easeInOut,
              ).transform(_expenseAnimationController.value);
              final overlayOpacity = const Interval(
                0,
                0.15,
                curve: Curves.easeOut,
              ).transform(_expenseAnimationController.value);
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: _showExpenseOverlay,
                      child: Opacity(
                        opacity: 1 - progress,
                        child: summary,
                      ),
                    ),
                  ),
                  if (_showExpenseOverlay)
                    Positioned.fromRect(
                      rect: cardRect,
                      child: Opacity(
                        opacity: overlayOpacity,
                        child: ClipRect(
                          child: _buildExpanded(
                            cardRect.height,
                            contentProgress,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
