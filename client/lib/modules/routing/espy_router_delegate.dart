import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/routing/library_filter.dart';
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
  LibraryFilter? filter;

  void showLibrary() {
    path = EspyRoutePath.library();
    filter = null;
    notifyListeners();
  }

  void showFilter(LibraryFilter filter) {
    path = EspyRoutePath.filter(filter);
    this.filter = filter;
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
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG):
            const HomeIntent(),
      },
      child: Navigator(
        key: navigatorKey,
        pages: [
          GameLibraryPage(),
          if (path.isDetailsPage)
            GameDetailsPage(
                entry: context
                    .read<GameEntriesModel>()
                    .getEntryById(path.gameId!)!),
        ],
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }
          // TODO: This forces the rebuild of the previous page, which among
          // other things breaks animations. However, it's the only way I could
          // update the path state.
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
    } else if (path.isFilterPage) {
      showFilter(path.filter!);
    } else if (path.isDetailsPage) {
      showGameDetails(path.gameId!);
    } else if (path.isUnmatchedPage) {
      showUnmatchedEntries();
    } else if (path.isTagsPage) {
      showTags();
    }
  }
}
