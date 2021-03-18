import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/screens/espy_home.dart';
import 'package:espy/proto/library.pb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
      create: (_context) {
        final model = GameLibraryModel();
        model.fetch();
        return model;
      },
    ),
    ChangeNotifierProvider(create: (_context) => GameDetailsModel())
  ], child: EspyApp()));
}

class EspyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _EspyAppState();
}

class _EspyAppState extends State<EspyApp> {
  EspyRouterDelegate _routerDelegate = EspyRouterDelegate();
  EspyRouteInformationParser _routeInformationParser =
      EspyRouteInformationParser();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'espy',
      theme: ThemeData.dark(),
      routeInformationParser: _routeInformationParser,
      routerDelegate: _routerDelegate,
    );
  }
}

class EspyRoutePath {
  final String? entryId;

  EspyRoutePath.home() : entryId = null;
  EspyRoutePath.entry(this.entryId);

  bool get isHomePage => entryId == null;
  bool get isGameDetailsPage => entryId != null;
}

class EspyRouterDelegate extends RouterDelegate<EspyRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<EspyRoutePath> {
  final GlobalKey<NavigatorState> navigatorKey;

  String? _gameId;

  EspyRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    print("building with _gameId=$_gameId");
    if (_gameId != null) {
      final entry = context
          .read<GameLibraryModel>()
          .getEntryById(int.tryParse(_gameId!)!);
      if (entry != null) {
        context.read<GameDetailsModel>().open(entry);
      }
    }

    return EspyHome(title: 'espy');
  }

  @override
  Future<void> setNewRoutePath(EspyRoutePath path) async {
    if (path.isGameDetailsPage) {
      _gameId = path.entryId;
      print("setNewRoutePath $_gameId");
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
    print(uri);

    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == "game") {
      print(uri.pathSegments);
      var gameId = uri.pathSegments[1];
      return EspyRoutePath.entry(gameId);
    } else {
      return EspyRoutePath.home();
    }
  }

  @override
  RouteInformation? restoreRouteInformation(EspyRoutePath path) {
    print("restoreRouteInformation");
    if (path.isHomePage) {
      return RouteInformation(location: '/');
    }
    if (path.isGameDetailsPage) {
      return RouteInformation(location: '/game/${path.entryId}');
    }
    return null;
  }
}
