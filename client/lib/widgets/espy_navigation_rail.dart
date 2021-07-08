import 'package:espy/modules/models/appbar_search_model.dart';
import 'package:espy/modules/models/library_filters_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/settings_dialog.dart';
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
    final user = context.watch<UserModel>();
    return NavigationRail(
      extended: extended,
      labelType: NavigationRailLabelType.selected,
      selectedIndex: _selectedIndex,
      leading: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            child: user.signedIn
                ? ClipOval(
                    child: Image.network(user.user.photoURL),
                  )
                : Icon(Icons.person),
          ),
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
          icon: Icon(Icons.bubble_chart_outlined),
          selectedIcon: Icon(Icons.bubble_chart),
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

        if (index != 3) {
          context.read<AppBarSearchModel>().clear();
        }

        if (index == 0) {
          context.read<LibraryFiltersModel>().clearFilter();
          context.read<EspyRouterDelegate>().showLibrary();
        } else if (index == 1) {
          context.read<LibraryFiltersModel>().clearFilter();
          context.read<EspyRouterDelegate>().showUnmatchedEntries();
        } else if (index == 2) {
          context.read<LibraryFiltersModel>().clearFilter();
          context.read<EspyRouterDelegate>().showTags();
        } else if (index == 3) {
          setState(() {});
          SettingsDialog.show(context);
        }
      },
    );
  }
}
