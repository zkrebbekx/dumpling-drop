import 'package:flutter/material.dart';

import '../audio/sfx.dart';
import '../theme.dart';

/// A row of up to three stars. When [animated], stars pop in one by
/// one with a sound.
class StarsRow extends StatelessWidget {
  final int stars;
  final double size;
  final bool animated;

  const StarsRow({
    super.key,
    required this.stars,
    this.size = 44,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          _Star(
            earned: i < stars,
            size: size,
            delay: animated ? Duration(milliseconds: 350 + i * 380) : null,
          ),
      ],
    );
  }
}

class _Star extends StatefulWidget {
  final bool earned;
  final double size;
  final Duration? delay;

  const _Star({required this.earned, required this.size, this.delay});

  @override
  State<_Star> createState() => _StarState();
}

class _StarState extends State<_Star> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    final delay = widget.delay;
    if (delay == null) {
      _controller.value = 1;
    } else if (widget.earned) {
      Future.delayed(delay, () {
        if (!mounted) return;
        Sfx.instance.play(Sound.star);
        _controller.forward();
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.size * 0.06),
        child: Icon(
          Icons.star_rounded,
          size: widget.size,
          color: widget.earned
              ? DumplingTheme.star
              : DumplingTheme.ink.withValues(alpha: 0.15),
          shadows: widget.earned
              ? [
                  Shadow(
                    color: DumplingTheme.star.withValues(alpha: 0.6),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
