import 'package:flutter/material.dart';

@immutable
class ExpandableButton extends StatefulWidget {
  const ExpandableButton({
    super.key,
    this.initialOpen = false,
    this.offset = const Offset(0, 0),
    required this.collapsedWidget,
    required this.expansionBuilder,
    this.closeButton,
  });

  final bool initialOpen;
  final Offset offset;
  final Widget collapsedWidget;
  final Widget Function(BuildContext, Animation<double>, Function())
      expansionBuilder;
  final Widget? closeButton;

  @override
  State<ExpandableButton> createState() => _ExpandableButtonState();
}

class _ExpandableButtonState extends State<ExpandableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  final layerLink = LayerLink();
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen;
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
          collapsedWidget(context),
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

  Widget collapsedWidget(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: IgnorePointer(
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
              onPressed: () {
                _toggle();
                expandWidget(context);
              },
              icon: widget.collapsedWidget,
            ),
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

  void expandWidget(BuildContext context) {
    Overlay.of(context).insert(
      OverlayEntry(
        builder: (context) {
          return AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Positioned(
                top: 200,
                child: CompositedTransformFollower(
                  link: layerLink,
                  showWhenUnlinked: false,
                  followerAnchor: Alignment.bottomCenter,
                  targetAnchor: Alignment.bottomCenter,
                  offset: widget.offset,
                  child: child!,
                ),
              );
            },
            child: FadeTransition(
              opacity: _expandAnimation,
              child: IgnorePointer(
                ignoring: !_open,
                child:
                    widget.expansionBuilder(context, _expandAnimation, _toggle),
              ),
            ),
          );
        },
      ),
    );
  }
}
