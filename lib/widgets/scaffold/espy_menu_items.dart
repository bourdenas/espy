import 'package:espy/modules/models/failed_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MenuItem {
  MenuItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
    this.badgeCount,
  });

  bool showBadge(context) => badgeCount != null && badgeCount!(context) > 0;
  Widget badgeLabel(context) => Text('${badgeCount!(context)}');

  final String label;
  final IconData? icon;
  final IconData? selectedIcon;
  final Function(BuildContext context) onTap;
  final int Function(BuildContext context)? badgeCount;
}

List<MenuItem> espyMenuItems = [
  MenuItem(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    onTap: (context) => context.goNamed('home'),
  ),
  MenuItem(
    label: 'Library',
    icon: Icons.games_outlined,
    selectedIcon: Icons.games,
    onTap: (context) => context.goNamed('games'),
  ),
  MenuItem(
    label: 'Untagged',
    icon: Icons.label_off_outlined,
    selectedIcon: Icons.label_off,
    onTap: (context) => context.goNamed('games',
        queryParameters: LibraryFilter(view: LibraryView.untagged).params()),
  ),
  MenuItem(
    label: 'Failed',
    icon: Icons.error_outline,
    selectedIcon: Icons.error,
    onTap: (context) => context.goNamed('unmatched'),
    badgeCount: (context) => context.watch<FailedModel>().entries.length,
  ),
];
