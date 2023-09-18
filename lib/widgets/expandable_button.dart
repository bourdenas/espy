import 'dart:math' as math;

import 'package:flutter/material.dart';

// A copy of the Expandable FAB from
// https://docs.flutter.dev/cookbook/effects/expandable-fab with some
// adjustments.
@immutable
class ExpandableButton extends StatefulWidget {
  const ExpandableButton({
    super.key,
    this.initialOpen,
    required this.collapsedWidget,
    required this.expansionWidgets,
    required this.distance,
    this.closeButton,
  });

  final bool? initialOpen;
  final double distance;
  final Widget collapsedWidget;
  final List<Widget> expansionWidgets;
  final Widget? closeButton;

  @override
  State<ExpandableButton> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          closeButton(),
          collapsedWidget(),
          expandedWidget(),
        ],
      ),
    );
  }

  Widget closeButton() {
    return AnimatedContainer(
      transformAlignment: Alignment.center,
      transform: Matrix4.diagonal3Values(
        !_open ? 0.7 : 1.0,
        !_open ? 0.7 : 1.0,
        1.0,
      ),
      duration: const Duration(milliseconds: 250),
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      child: AnimatedOpacity(
        opacity: !_open ? 0.0 : 1.0,
        curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
        duration: const Duration(milliseconds: 250),
        child: widget.closeButton ?? closeWidget(),
      ),
    );
  }

  Widget collapsedWidget() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: IconButton(
            onPressed: () => _toggle(),
            icon: widget.collapsedWidget,
          ),
        ),
      ),
    );
  }

  Widget closeWidget() {
    return IconButton(
      onPressed: () => _toggle(),
      icon: const Icon(
        Icons.close,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget expandedWidget() {
    final expansion = Card(
      elevation: 16,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: widget.expansionWidgets,
        ),
      ),
    );

    // return Positioned(
    //   top: widget.distance,
    //   child: expansion,
    // );

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Positioned(
          top: _expandAnimation.value * widget.distance,
          child: child!,
        );
      },
      child: FadeTransition(
        opacity: _expandAnimation,
        child: IgnorePointer(
          ignoring: !_open,
          child: expansion,
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        return Positioned(
          top: progress.value * maxDistance,
          child: child!,
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: IgnorePointer(
          ignoring: progress.value < 0.5,
          child: child,
        ),
      ),
    );
  }
}
