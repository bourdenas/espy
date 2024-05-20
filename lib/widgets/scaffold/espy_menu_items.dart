import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/unresolved_model.dart';
import 'package:espy/pages/espy_navigator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
    requiresSignIn: true,
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
    onTap: (context) => setLibraryView(context, LibraryFilter()),
  ),
  MenuItem(
    requiresSignIn: true,
    label: 'Browse',
    icon: Icons.bookmark_outline,
    selectedIcon: Icons.bookmark,
    onTap: (context) => context.goNamed('browse'),
  ),
  MenuItem(
    requiresSignIn: false,
    label: 'Years',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
    onTap: (context) => context.goNamed('years'),
  ),
  MenuItem(
    requiresSignIn: false,
    label: 'Timeline',
    icon: Icons.timeline_outlined,
    selectedIcon: Icons.timeline,
    onTap: (context) {
      final DateFormat formatter = DateFormat('MMM');
      final now = DateTime.now();
      context.goNamed('releases', pathParameters: {
        'label': formatter.format(now),
        'year': '${now.year}',
      });
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
];
