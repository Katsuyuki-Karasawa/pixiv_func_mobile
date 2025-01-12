import 'package:flutter/material.dart';

class NoScrollBehaviorWidget extends StatelessWidget {
  final Widget child;

  const NoScrollBehaviorWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(behavior: _NoScrollBehavior(), child: child);
  }
}

class _NoScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
        return child;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return GlowingOverscrollIndicator(
          axisDirection: details.direction,
          color: Theme.of(context).colorScheme.primary,
          showTrailing: false,
          showLeading: false,
          child: child,
        );
      case TargetPlatform.linux:
        break;
      case TargetPlatform.macOS:
        break;
      case TargetPlatform.windows:
        break;
    }
    return child;
  }
}
