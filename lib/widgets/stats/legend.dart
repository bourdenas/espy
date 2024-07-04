import 'package:flutter/material.dart';

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

const legendColors = {
  'Adventure': Colors.blue,
  'RPG': Colors.deepPurple,
  'Strategy': Colors.green,
  'Action': Colors.indigo,
  'Shooter': Colors.amber,
  'Platformer': Colors.deepOrange,
  'Simulator': Colors.teal,
  'Casual': Colors.pink,
  'Arcade': Colors.lightGreen,
  'Unknown': Colors.grey,
};
