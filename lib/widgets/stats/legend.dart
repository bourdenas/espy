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

const legendColors = [
  Colors.blue,
  Colors.deepOrange,
  Colors.orange,
  Colors.green,
  Colors.deepPurple,
  Colors.teal,
  Colors.lightGreen,
  Colors.pink,
  Colors.grey,
  Colors.purple,
  Colors.amber,
];
