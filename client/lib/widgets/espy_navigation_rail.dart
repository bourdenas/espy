import 'package:espy/constants/menu_items.dart' show menu_items;
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/proto/igdbapi.pb.dart';
import 'package:espy/proto/library.pb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EspyNavigationRail extends StatelessWidget {
  final bool extended;

  const EspyNavigationRail(this.extended);

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: extended,
      selectedIndex: 0,
      destinations: menu_items
          .map((item) => NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              ))
          .toList(),
      onDestinationSelected: (index) {
        context.read<EspyRouterDelegate>().goHome();
        context.read<GameLibraryModel>().update(Library()
          ..entry
              .add(GameEntry()..game = (Game()..name = 'New Game ($index)')));
      },
    );
  }
}
