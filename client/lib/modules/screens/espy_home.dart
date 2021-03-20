import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/modules/screens/game_screen.dart';
import 'package:espy/widgets/espy_drawer.dart' show EspyDrawer;
import 'package:espy/widgets/espy_game_grid.dart';
import 'package:espy/widgets/espy_navigation_rail.dart' show EspyNavigationRail;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EspyHome extends StatelessWidget {
  EspyHome({
    Key? key,
    required this.title,
    required this.navigatorKey,
    this.gameId,
  }) : super(key: key);

  final GlobalKey<NavigatorState> navigatorKey;
  final String title;
  final String? gameId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
                icon: const Icon(Icons.search),
                onPressed: () =>
                    showSearch(context: context, delegate: Search()))
          ],
        ),
        drawer: constraints.maxWidth <= 800 ? EspyDrawer() : null,
        body: Row(children: [
          if (constraints.maxWidth > 800) ...[
            EspyNavigationRail(constraints.maxWidth > 1200),
            VerticalDivider(thickness: 1, width: 1)
          ],
          Expanded(
            child: Navigator(
              key: navigatorKey,
              pages: [
                MaterialPage(
                  key: ValueKey('LibraryGridPage'),
                  child: EspyGameGrid(),
                ),
                if (gameId != null)
                  GameDetailsPage(
                      entry: context
                          .watch<GameLibraryModel>()
                          .getEntryById(gameId!)!),
              ],
              onPopPage: (route, result) {
                if (!route.didPop(result)) {
                  return false;
                }

                context.read<EspyRouterDelegate>().goHome();
                return true;
              },
            ),
          ),
        ]),
      );
    });
  }
}

class Search extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: Icon(Icons.close), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context));
  }

  String selectedResult = '';

  @override
  Widget buildResults(BuildContext context) {
    return Container(child: Center(child: Text(selectedResult)));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> suggestions = ['Adventure', 'Strategy', 'RPG'];

    return ListView.builder(itemBuilder: (context, index) {
      return ListTile(title: Text(suggestions[index]));
    });
  }
}
