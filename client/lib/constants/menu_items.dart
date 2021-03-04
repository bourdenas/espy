import 'package:flutter/material.dart' show IconData, Icons;

class MenuItem {
  const MenuItem({required this.label, this.icon, this.selectedIcon});

  final String label;
  final IconData? icon;
  final IconData? selectedIcon;
}

const List<MenuItem> menu_items = [
  MenuItem(
    label: 'Steam',
    icon: Icons.bookmark_border,
    selectedIcon: Icons.bookmark,
  ),
  MenuItem(
    label: 'GOG',
    icon: Icons.bookmark_border,
    selectedIcon: Icons.bookmark,
  ),
  MenuItem(
    label: 'Epic',
    icon: Icons.bookmark_border,
    selectedIcon: Icons.bookmark,
  ),
  MenuItem(
    label: 'Custom Label',
    icon: Icons.bookmark_border,
    selectedIcon: Icons.bookmark,
  ),
];
