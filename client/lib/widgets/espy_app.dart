import 'package:espy/modules/routing/espy_route_information_parser.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:firebase_core/firebase_core.dart';
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

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    _routerDelegate = context.watch<EspyRouterDelegate>();
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("Failed to connect to Firebase: ${snapshot.error}");
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp.router(
            title: 'espy',
            theme: ThemeData.dark(),
            routerDelegate: _routerDelegate!,
            routeInformationParser: _routeInformationParser,
            debugShowCheckedModeBanner: false,
          );
        }

        return Text('loading...');
      },
    );
  }
}
