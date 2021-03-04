import 'package:espy/constants/menu_items.dart' show menu_items;
import 'package:flutter/material.dart';

class EspyNavigationRail extends StatelessWidget {
  final bool extended;

  const EspyNavigationRail(this.extended);

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: extended,
      selectedIndex: 0,
      destinations: menu_items
          .map((item) => NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              ))
          .toList(),
    );
  }
}
