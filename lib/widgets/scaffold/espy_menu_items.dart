import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/unresolved_model.dart';
import 'package:espy/pages/espy_navigator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MenuItem {
  MenuItem({
    required this.requiresSignIn,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
    this.badgeCount,
  });

  bool showBadge(context) => badgeCount != null && badgeCount!(context) > 0;
  Widget badgeLabel(context) => Text('${badgeCount!(context)}');

  final bool requiresSignIn;
  final String label;
  final IconData? icon;
  final IconData? selectedIcon;
  final Function(BuildContext context) onTap;
  final int Function(BuildContext context)? badgeCount;
}

List<MenuItem> espyMenuItems = [
  MenuItem(
    requiresSignIn: false,
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    onTap: (context) => context.goNamed('home'),
  ),
  MenuItem(
    requiresSignIn: true,
    label: 'Library',
    icon: Icons.games_outlined,
    selectedIcon: Icons.games,
    onTap: (context) => setLibraryView(context),
  ),
  MenuItem(
    requiresSignIn: true,
    label: 'Explore',
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore,
    onTap: (context) => context.goNamed('explore'),
  ),
  MenuItem(
    requiresSignIn: false,
    label: 'Calendar',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
    onTap: (context) {
      context.read<FilterModel>().clear();
      context.goNamed('calendar');
    },
  ),
  MenuItem(
    requiresSignIn: true,
    label: 'Unresolved',
    icon: Icons.task_alt_outlined,
    selectedIcon: Icons.task_alt,
    onTap: (context) => context.goNamed('unresolved'),
    badgeCount: (context) => context.watch<UnresolvedModel>().unknown.length,
  ),
  MenuItem(
    requiresSignIn: false,
    label: 'Search',
    icon: Icons.search_outlined,
    selectedIcon: Icons.search,
    onTap: (context) => context.goNamed('search'),
  ),
];
