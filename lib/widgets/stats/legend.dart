import 'package:flutter/material.dart';
import 'package:quiver/iterables.dart';

class Legend extends StatelessWidget {
  const Legend(
    this.items, {
    super.key,
    this.itemPops,
    this.selectedItem,
    this.palette,
    this.onItemTap,
    this.backLabel,
    this.onBack,
    this.width = 170,
  });

  final List<String> items;
  final Map<String, int>? itemPops;
  final String? selectedItem;
  final List<Color?>? palette;
  final void Function(String selectedItem)? onItemTap;
  final String? backLabel;
  final void Function()? onBack;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ListView(
        children: [
          if (backLabel != null) ...[
            backButton(),
            const SizedBox(height: 4),
          ],
          for (final item in enumerate(items))
            LegendKey(
              color: palette?[item.index % items.length],
              text: item.value,
              textColor: item.value == selectedItem
                  ? Colors.blue
                  : itemPops?[item.value] != null
                      ? Colors.white
                      : Colors.grey,
              isSquare: true,
              onTap: () => onItemTap?.call(item.value),
            ),
        ],
      ),
    );
  }

  Widget backButton() {
    return LegendKey(
      color: Colors.white,
      text: backLabel!,
      isSquare: true,
      icon: Icons.keyboard_arrow_left,
      onTap: () => onBack?.call(),
    );
  }
}

class LegendKey extends StatelessWidget {
  const LegendKey({
    super.key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor,
    this.icon,
    this.onTap,
  });
  final Color? color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;
  final IconData? icon;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          if (icon != null)
            Icon(icon)
          else
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
                color: color,
              ),
            ),
          const SizedBox(
            width: 6,
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          )
        ],
      ),
    );
  }
}
