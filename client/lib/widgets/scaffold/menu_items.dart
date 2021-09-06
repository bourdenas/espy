import 'package:espy/modules/models/appbar_search_model.dart';
import 'package:espy/modules/models/filters_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/dialogs/settings_dialog.dart';
import 'package:flutter/material.dart' show BuildContext, IconData, Icons;
import 'package:provider/provider.dart';

class MenuItem {
  MenuItem({
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

List<MenuItem> menuItems = [
  MenuItem(
    label: 'Library',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    onTap: (context) {
      context.read<AppBarSearchModel>().clear();
      context.read<FiltersModel>().clearFilter();
      context.read<EspyRouterDelegate>().showLibrary();
    },
  ),
  MenuItem(
    label: 'Tags',
    icon: Icons.bubble_chart_outlined,
    selectedIcon: Icons.bubble_chart,
    onTap: (context) {
      context.read<AppBarSearchModel>().clear();
      context.read<FiltersModel>().clearFilter();
      context.read<EspyRouterDelegate>().showTags();
    },
  ),
  MenuItem(
    label: 'Unmatched',
    icon: Icons.cloud_off_outlined,
    selectedIcon: Icons.cloud_off,
    onTap: (context) {
      context.read<AppBarSearchModel>().clear();
      context.read<FiltersModel>().clearFilter();
      context.read<EspyRouterDelegate>().showUnmatchedEntries();
    },
  ),
  MenuItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    onTap: (context) {
      SettingsDialog.show(context);
    },
  ),
];
