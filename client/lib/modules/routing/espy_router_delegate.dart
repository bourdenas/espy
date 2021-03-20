import 'package:espy/modules/models/game_library_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:espy/modules/screens/espy_home.dart';
import 'package:espy/modules/screens/game_screen.dart';

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

class EspyRouteInformationParser extends RouteInformationParser<EspyRoutePath> {
  @override
  Future<EspyRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    if (routeInformation.location == null) {
      return EspyRoutePath.home();
    }

    final uri = Uri.parse(routeInformation.location!);
    print('parseRouteInformation=$uri');

    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'game') {
      var gameId = uri.pathSegments[1];
      return EspyRoutePath.entry(gameId);
    } else {
      return EspyRoutePath.home();
    }
  }

  @override
  RouteInformation? restoreRouteInformation(EspyRoutePath path) {
    if (path.isHomePage) {
      return RouteInformation(location: '/');
    }
    if (path.isGameDetailsPage) {
      return RouteInformation(location: '/game/${path.entryId}');
    }
    return null;
  }
}

class EspyRoutePath {
  final String? entryId;

  EspyRoutePath.home() : entryId = null;
  EspyRoutePath.entry(this.entryId);

  bool get isHomePage => entryId == null;
  bool get isGameDetailsPage => entryId != null;
}
