import 'package:flutter/material.dart';

class SwipeBackDetector extends StatefulWidget {
  final Widget child;

  const SwipeBackDetector({super.key, required this.child});

  @override
  State<SwipeBackDetector> createState() => _SwipeBackDetectorState();
}

class _SwipeBackDetectorState extends State<SwipeBackDetector> {
  bool _popped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        // Allow swipe from the left edge (dx < 50) and moving right
        if (details.globalPosition.dx < 50 && details.primaryDelta! > 5) {
          if (!_popped && Navigator.canPop(context)) {
            _popped = true;
            Navigator.pop(context);
          }
        }
      },
      child: widget.child,
    );
  }
}
