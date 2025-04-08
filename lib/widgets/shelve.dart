import 'package:flutter/material.dart';

class Shelve extends StatefulWidget {
  const Shelve({
    super.key,
    required this.title,
    required this.expansion,
    this.color,
    this.onTitleTap,
    this.expanded = true,
  });

  final String title;
  final Widget expansion;
  final Color? color;
  final void Function()? onTitleTap;

  final bool expanded;

  @override
  State<Shelve> createState() => _ShelveState();
}

class _ShelveState extends State<Shelve> {
  bool expanded = false;

  @override
  void initState() {
    super.initState();
    expanded = widget.expanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        header(context),
        if (expanded) widget.expansion,
      ],
    );
  }

  Widget header(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => expanded = !expanded),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(expanded ? Icons.arrow_drop_down : Icons.arrow_right),
            TextButton(
              onPressed: widget.onTitleTap,
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16.0,
                  color: widget.color,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
