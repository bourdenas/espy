import 'package:espy/constants/menu_items.dart' show menu_items;
import 'package:espy/modules/models/game_library_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final tags = context.watch<GameLibraryModel>().tags;

    return NavigationRail(
      extended: extended,
      selectedIndex: _selectedIndex,
      destinations: [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
        ...tags
            .take(15)
            .map((tag) => NavigationRailDestination(
                  icon: Icon(Icons.bookmark_border),
                  selectedIcon: Icon(Icons.bookmark),
                  label: Text(tag),
                ))
            .toList(),
      ],
      onDestinationSelected: (index) {
        _selectedIndex = index;
        if (index == 0) {
          context.read<GameLibraryModel>().clearFilter();
        } else if (index == 1) {
          // TODO: Settings page.
        } else if (index > 1) {
          context.read<GameLibraryModel>().clearFilter();
          context.read<GameLibraryModel>().addTagFilter(tags[index - 2]);
        }
      },
    );
  }
}
