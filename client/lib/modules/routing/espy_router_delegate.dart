import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/pages/game_details_page.dart';
import 'package:espy/modules/pages/game_library_page.dart';
import 'package:espy/modules/routing/espy_route_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class EspyRouterDelegate extends RouterDelegate<EspyRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<EspyRoutePath> {
  final GlobalKey<NavigatorState> navigatorKey;

  EspyRoutePath path = EspyRoutePath.library();

  void showLibrary() {
    path = EspyRoutePath.library();
    notifyListeners();
  }

  void showGameDetails(String id) {
    path = EspyRoutePath.details(id);
    notifyListeners();
  }

  void showUnmatchedEntries() {
    path = EspyRoutePath.unmatched();
    notifyListeners();
  }

  void showTags() {
    path = EspyRoutePath.tags();
    notifyListeners();
  }

  EspyRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();

  @override
  EspyRoutePath get currentConfiguration => path;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const SearchIntent(),
      },
      child: Navigator(
        key: navigatorKey,
        pages: [
          GameLibraryPage(),
          if (path.isDetailsPage)
            GameDetailsPage(
                entry: context
                    .watch<GameEntriesModel>()
                    .getEntryById(path.gameId!)!),
        ],
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }
          showLibrary();
          return true;
        },
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(EspyRoutePath path) async {
    if (path.isLibraryPage) {
      showLibrary();
    } else if (path.isDetailsPage) {
      showGameDetails(path.gameId!);
    } else if (path.isUnmatchedPage) {
      showUnmatchedEntries();
    } else if (path.isTagsPage) {
      showTags();
    }
  }
}
