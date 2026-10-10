import 'package:flutter/material.dart';

/// Fades and slides [child] in once, after a delay based on [index], so a
/// list of them appears one after another.
class Reveal extends StatelessWidget {
  final Widget child;
  final int index;

  const Reveal({super.key, required this.child, this.index = 0});

  /// Wraps [children] so they appear one after another.
  static List<Widget> stagger(List<Widget> children) => [
    for (var i = 0; i < children.length; i++)
      Reveal(index: i, child: children[i]),
  ];

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = (index * 70).clamp(0, 560);
    final total = 420 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}
