import 'dart:html';

import 'package:espy/modules/models/config_model.dart';
import 'package:espy/modules/routing/espy_route_information_parser.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EspyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _EspyAppState();
}

class _EspyAppState extends State<EspyApp> {
  EspyRouterDelegate? _routerDelegate;
  EspyRouteInformationParser _routeInformationParser =
      EspyRouteInformationParser();

  @override
  void initState() {
    super.initState();

    // Prevent default event handler
    document.onContextMenu.listen((event) => event.preventDefault());
  }

  @override
  Widget build(BuildContext context) {
    _routerDelegate = context.watch<EspyRouterDelegate>();
    return MaterialApp.router(
      title: 'espy',
      theme: context.watch<AppConfig>().theme,
      routerDelegate: _routerDelegate!,
      routeInformationParser: _routeInformationParser,
      debugShowCheckedModeBanner: false,
    );
  }
}
