import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/pages/game_details_page.dart';
import 'package:espy/modules/pages/game_library_page.dart';
import 'package:espy/modules/routing/espy_route_path.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EspyRouterDelegate extends RouterDelegate<EspyRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<EspyRoutePath> {
  final GlobalKey<NavigatorState> navigatorKey;

  String? _gameId;

  set gameId(String id) {
    _gameId = id;
    notifyListeners();
  }

  void goHome() {
    _gameId = null;
    notifyListeners();
  }

  EspyRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();

  @override
  EspyRoutePath get currentConfiguration =>
      _gameId == null ? EspyRoutePath.home() : EspyRoutePath.entry(_gameId);

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        GameLibraryPage(),
        if (_gameId != null)
          GameDetailsPage(
              entry: context.watch<GameLibraryModel>().getEntryById(_gameId!)!),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }

        context.read<EspyRouterDelegate>().goHome();
        return true;
      },
    );

    // EspyHome(title: 'espy', navigatorKey: navigatorKey, gameId: _gameId);
  }

  @override
  Future<void> setNewRoutePath(EspyRoutePath path) async {
    if (path.isHomePage) {
      goHome();
    }
    if (path.isGameDetailsPage) {
      gameId = path.entryId!;
    }
  }
}
