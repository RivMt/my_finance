import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_api/finance.dart';

/// Edits the pin or hidden priority state of a [WalletItem].
class PriorityEditFragment<T extends WalletItem> extends StatelessWidget {
  const PriorityEditFragment({
    super.key,
    required this.data,
    required this.onPressed,
  });

  /// Wallet item whose priority is being edited.
  final T data;

  /// Called with `1`, `0`, or `-1` for pinned, normal, or hidden.
  final Function(int) onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pin or unpin visible items.
        Visibility(
          visible: data.priority >= 0,
          child: IconButton(
            icon: Icon(data.priority > 0
                ? Icons.star
                : Icons.star_border_outlined
            ),
            color: data.priority > 0
                ? Theme.of(context).primaryColor
                : AppTheme.swatches.contentSecondary,
            onPressed: () => onPressed(data.priority > 0 ? 0 : 1),
          ),
        ),
        // Hide or reveal unpinned items.
        Visibility(
          visible: data.priority <= 0,
          child: IconButton(
            icon: Icon(data.priority < 0
                ? Icons.visibility_off_outlined
                : Icons.visibility
            ),
            color: data.priority < 0
                ? AppTheme.swatches.contentSecondary
                : Theme.of(context).primaryColor,
            onPressed: () => onPressed(data.priority < 0 ? 0 : -1),
          ),
        ),
      ],
    );
  }
}
