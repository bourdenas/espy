import 'package:badges/badges.dart';
import 'package:espy/modules/models/failed_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EspyNavigationRail extends StatefulWidget {
  final bool extended;
  final String path;

  const EspyNavigationRail(this.extended, this.path);

  @override
  State<StatefulWidget> createState() {
    return EspyNavigationRailState();
  }
}

class EspyNavigationRailState extends State<EspyNavigationRail> {
  int _selectedIndex = 0;
  Map<String, int> _mapping = {
    '/': 0,
    '/games': 1,
    '/unmatched': 3,
    '/profile': 4,
  };

  @override
  void initState() {
    super.initState();

    _selectedIndex = _mapping[widget.path] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return NavigationRail(
      extended: widget.extended,
      labelType: !widget.extended ? NavigationRailLabelType.selected : null,
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
                icon: e.badgeText != null
                    ? Badge(
                        badgeContent: e.badgeText!(context),
                        position: BadgePosition.topEnd(top: -24, end: -16),
                        borderRadius: BorderRadius.circular(1),
                        child: Icon(e.icon),
                      )
                    : Icon(e.icon),
                selectedIcon: Icon(e.selectedIcon),
              ))
          .toList(),
      onDestinationSelected: (index) {
        _menuItems[index].onTap(context);
        setState(() {
          _selectedIndex = index;
        });
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
    this.badgeText,
  });

  final String label;
  final IconData? icon;
  final IconData? selectedIcon;
  final Function(BuildContext context) onTap;
  final Widget Function(BuildContext context)? badgeText;
}

List<_MenuItem> _menuItems = [
  _MenuItem(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    onTap: (context) => context.goNamed('home'),
  ),
  _MenuItem(
    label: 'Library',
    icon: Icons.games_outlined,
    selectedIcon: Icons.games,
    onTap: (context) => context.pushNamed('games'),
  ),
  _MenuItem(
    label: 'Untagged',
    icon: Icons.label_off_outlined,
    selectedIcon: Icons.label_off,
    onTap: (context) => context.pushNamed('games',
        queryParams: LibraryFilter(untagged: true).params()),
  ),
  _MenuItem(
    label: 'Failed',
    icon: Icons.error_outline,
    selectedIcon: Icons.error,
    onTap: (context) => context.pushNamed('unmatched'),
    badgeText: (context) =>
        Text('${context.watch<FailedModel>().entries.length}'),
  ),
  _MenuItem(
    label: 'Settings',
    icon: Icons.settings,
    selectedIcon: Icons.settings,
    onTap: (context) => context.pushNamed('profile'),
  ),
];
