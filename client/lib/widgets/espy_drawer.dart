import 'package:espy/constants/menu_items.dart' show menu_items;
import 'package:flutter/material.dart';

class EspyDrawer extends StatelessWidget {
  const EspyDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Text('User'),
          ),
          for (final item in menu_items)
            ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              onTap: () {},
            ),
        ],
      ),
    );
  }
}
