import 'package:flutter/material.dart';

@immutable
class SlidingChip extends StatefulWidget {
  const SlidingChip({
    super.key,
    required this.label,
    required this.expansion,
    this.color,
    this.backgroundColor,
    this.onExpand,
    this.initialOpen = false,
  });

  final String label;
  final Widget expansion;
  final Color? color;
  final Color? backgroundColor;
  final void Function()? onExpand;
  final bool initialOpen;

  @override
  State<SlidingChip> createState() => _SlidingChipState();
}

class _SlidingChipState extends State<SlidingChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  final layerLink = LayerLink();

  bool open = false;
  List<OverlayEntry> overlays = [];

  @override
  void initState() {
    super.initState();
    open = widget.initialOpen;
    _controller = AnimationController(
      value: open ? 1.0 : 0.0,
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
      open = !open;
      if (open) {
        _controller.forward();
      } else {
        _controller.reverse().whenComplete(() {
          for (final overlay in overlays) {
            overlay.remove();
          }
          overlays.clear();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return open
        ? Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
            child: Row(children: [
              closeButton(),
              expandedWidget(context),
            ]),
          )
        : topButton(context);
  }

  Widget closeButton() {
    return AnimatedOpacity(
      opacity: !open ? 0.0 : 1.0,
      curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
      duration: const Duration(milliseconds: 250),
      child: closeWidget(),
    );
  }

  Widget closeWidget() {
    return IconButton(
      onPressed: () => _toggle(),
      icon: Icon(
        Icons.keyboard_double_arrow_left,
        color: widget.color,
        size: 24,
      ),
    );
  }

  Widget topButton(BuildContext context) {
    return InputChip(
      label: Row(
        children: [
          Icon(
            Icons.keyboard_double_arrow_right,
            color: widget.color,
          ),
          const SizedBox(width: 4),
          Text(
            widget.label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: widget.color),
          ),
        ],
      ),
      backgroundColor: widget.backgroundColor,
      onPressed: () {
        if (!open) {
          widget.onExpand?.call();
        }
        _toggle();
      },
    );
  }

  Widget expandedWidget(BuildContext context) {
    return widget.expansion;
  }
}
