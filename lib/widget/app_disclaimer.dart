import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:my_api/core.dart';
import 'package:my_finance/generated/locale_keys.g.dart';

/// Displays disclaimers appropriate for the current application mode.
class AppDisclaimer extends StatelessWidget {
  /// Creates an application disclaimer.
  const AppDisclaimer({
    super.key,
    required this.mode,
  });

  /// Current application mode.
  final AppMode mode;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleKeys.msgCommonDisclaimer.tr()),
        if (mode == AppMode.demo) ...[
          const SizedBox(height: 8),
          Text(LocaleKeys.msgDemoDisclaimer.tr()),
        ] else if (mode != AppMode.production) ...[
          const SizedBox(height: 8),
          Text(LocaleKeys.msgDevDisclaimer.tr()),
        ],
      ],
    );
  }
}
