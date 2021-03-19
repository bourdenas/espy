import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) {
          final model = GameLibraryModel();
          model.fetch();
          return model;
        },
      ),
      ChangeNotifierProvider(create: (context) => EspyRouterDelegate()),
    ],
    child: EspyApp(),
  ));
}

class EspyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _EspyAppState();
}

class _EspyAppState extends State<EspyApp> {
  EspyRouterDelegate? _routerDelegate;
  EspyRouteInformationParser _routeInformationParser =
      EspyRouteInformationParser();

  @override
  Widget build(BuildContext context) {
    _routerDelegate = context.watch<EspyRouterDelegate>();
    return MaterialApp.router(
      title: 'espy',
      theme: ThemeData.dark(),
      routerDelegate: _routerDelegate!,
      routeInformationParser: _routeInformationParser,
      debugShowCheckedModeBanner: false,
    );
  }
}
