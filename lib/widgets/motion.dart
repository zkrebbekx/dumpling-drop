import 'dart:async';

import 'package:flutter/material.dart';

/// A playful page transition: the new screen pops in with a small
/// overshoot and a fade. Falls back to a plain fade when the platform
/// asks for reduced motion.
Route<T> bouncyRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (context, animation, _, child) {
      final fade = FadeTransition(opacity: animation, child: child);
      if (MediaQuery.of(context).disableAnimations) return fade;
      final scale = Tween<double>(begin: 0.86, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        ),
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

/// Pops its child in with an elastic scale after [delay]. Give list
/// items increasing delays for a stagger. Honors reduced motion.
class PopIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.4),
        ),
        child: widget.child,
      ),
    );
  }
}

/// A slow, gentle rocking sway. Used on the title. Honors reduced
/// motion by rendering the child still.
class Sway extends StatefulWidget {
  final Widget child;
  final double radians;

  const Sway({super.key, required this.child, this.radians = 0.02});

  @override
  State<Sway> createState() => _SwayState();
}

class _SwayState extends State<Sway> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.rotate(
        angle: (_controller.value * 2 - 1) * widget.radians,
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Counts a number up from zero when first shown.
class CountUp extends StatelessWidget {
  final int value;
  final TextStyle style;
  final String prefix;

  const CountUp({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Text('$prefix$value', style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text('$prefix${v.round()}', style: style),
    );
  }
}
