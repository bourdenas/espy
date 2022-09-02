import 'package:espy/modules/models/library_filter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EspyNavigationRail extends StatefulWidget {
  final bool extended;

  const EspyNavigationRail(this.extended);

  @override
  State<StatefulWidget> createState() {
    return EspyNavigationRailState(extended);
  }
}

class EspyNavigationRailState extends State<EspyNavigationRail> {
  final bool extended;
  int _selectedIndex = 0;

  EspyNavigationRailState(this.extended);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return NavigationRail(
      extended: extended,
      labelType: !extended ? NavigationRailLabelType.selected : null,
      selectedIndex: _selectedIndex,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          child: user != null
              ? ClipOval(
                  child: Image.network(user.photoURL!),
                )
              : Icon(Icons.person),
        ),
      ),
      groupAlignment: 0,
      destinations: _menuItems
          .map((e) => NavigationRailDestination(
                label: Text(e.label),
                icon: Icon(e.icon),
                selectedIcon: Icon(e.selectedIcon),
              ))
          .toList(),
      onDestinationSelected: (index) {
        _selectedIndex = index;
        _menuItems[_selectedIndex].onTap(context);
      },
    );
  }
}

class _MenuItem {
  _MenuItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final IconData? selectedIcon;
  final Function(BuildContext context) onTap;
}

List<_MenuItem> _menuItems = [
  _MenuItem(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    onTap: (context) => Navigator.pushNamed(context, '/home'),
  ),
  _MenuItem(
    label: 'Library',
    icon: Icons.games_outlined,
    selectedIcon: Icons.games,
    onTap: (context) => Navigator.pushNamed(context, '/games',
        arguments: LibraryFilter().encode()),
  ),
  _MenuItem(
    label: 'Untagged',
    icon: Icons.label_off_outlined,
    selectedIcon: Icons.label_off,
    onTap: (context) => Navigator.pushNamed(context, '/games',
        arguments: LibraryFilter(untagged: true).encode()),
  ),
  _MenuItem(
    label: 'Failed',
    icon: Icons.error_outline,
    selectedIcon: Icons.error,
    onTap: (context) => Navigator.pushNamed(context, '/unmatched'),
  ),
];
