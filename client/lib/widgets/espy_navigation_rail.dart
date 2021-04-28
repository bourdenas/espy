import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
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
    return NavigationRail(
      extended: extended,
      labelType: NavigationRailLabelType.selected,
      selectedIndex: _selectedIndex,
      leading: Column(children: [
        Padding(padding: EdgeInsets.symmetric(vertical: 8)),
        CircleAvatar(
          child: Icon(Icons.person),
        ),
      ]),
      groupAlignment: 0,
      destinations: [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Library'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.cloud_off_outlined),
          selectedIcon: Icon(Icons.cloud_off),
          label: Text('Unmatched'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.collections_bookmark_outlined),
          selectedIcon: Icon(Icons.collections_bookmark),
          label: Text('Tags'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
      onDestinationSelected: (index) {
        _selectedIndex = index;
        if (index == 0) {
          context.read<GameEntriesModel>().clearFilter();
          context.read<EspyRouterDelegate>().showLibrary();
        } else if (index == 1) {
          context.read<EspyRouterDelegate>().showUnmatchedEntries();
        } else if (index == 2) {
          context.read<EspyRouterDelegate>().showTags();
        } else if (index == 3) {
          // TODO: Settings page.
        }
      },
    );
  }
}
