import 'package:flutter/material.dart';

class HoverAnimation extends StatefulWidget {
  final Widget child;
  final double scale;

  final void Function(bool hover)? onHover;

  const HoverAnimation({
    super.key,
    required this.child,
    this.scale = 1.1,
    this.onHover,
  });

  @override
  State<HoverAnimation> createState() => _HoverAnimationState();
}

class _HoverAnimationState extends State<HoverAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    animation = Tween(begin: 1.0, end: widget.scale).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.ease,
      reverseCurve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        controller.forward();
        if (widget.onHover != null) widget.onHover!(true);
      },
      onExit: (_) {
        controller.reverse();
        if (widget.onHover != null) widget.onHover!(false);
      },
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return ScaleTransition(
            scale: animation,
            child: widget.child,
          );
        },
      ),
    );
  }
}
