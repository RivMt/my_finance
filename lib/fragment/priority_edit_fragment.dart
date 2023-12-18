import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';

class PriorityEditFragment<T extends WalletItem> extends StatelessWidget {
  const PriorityEditFragment({
    super.key,
    required this.data,
    required this.onPressed,
  });

  final T data;

  final Function(int) onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pin
        Visibility(
          visible: data.priority >= 0,
          child: IconButton(
            icon: Icon(data.priority > 0
                ? Icons.star
                : Icons.star_border_outlined
            ),
            color: data.priority > 0
                ? AppTheme.primary
                : AppTheme.contentSecondary,
            onPressed: () => onPressed(data.priority > 0 ? 0 : 1),
          ),
        ),
        // Hide
        Visibility(
          visible: data.priority <= 0,
          child: IconButton(
            icon: Icon(data.priority < 0
                ? Icons.visibility_off_outlined
                : Icons.visibility
            ),
            color: data.priority < 0
                ? AppTheme.contentSecondary
                : AppTheme.primary,
            onPressed: () => onPressed(data.priority < 0 ? 0 : -1),
          ),
        ),
      ],
    );
  }
}