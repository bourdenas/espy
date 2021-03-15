import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/screens/game_screen.dart';
import 'package:espy/widgets/espy_drawer.dart' show EspyDrawer;
import 'package:espy/widgets/espy_game_grid.dart';
import 'package:espy/widgets/espy_navigation_rail.dart' show EspyNavigationRail;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EspyHome extends StatelessWidget {
  EspyHome({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        drawer: constraints.maxWidth <= 800 ? EspyDrawer() : null,
        body: Row(children: [
          if (constraints.maxWidth > 800) ...[
            EspyNavigationRail(constraints.maxWidth > 1200),
            VerticalDivider(thickness: 1, width: 1)
          ],
          Expanded(
            child: Navigator(
              pages: [
                MaterialPage(
                  key: ValueKey('LibraryGridPage'),
                  child: EspyGameGrid(),
                ),
                if (context.watch<GameDetailsModel>().entry != null)
                  GameDetailsPage(
                      entry: context.watch<GameDetailsModel>().entry!),
              ],
              onPopPage: (route, result) {
                if (!route.didPop(result)) {
                  return false;
                }

                context.read<GameDetailsModel>().close();
                return true;
              },
            ),
          ),
        ]),
      );
    });
  }
}
