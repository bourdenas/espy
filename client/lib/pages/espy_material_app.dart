import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/game_details_page.dart';
import 'package:espy/pages/game_list_page.dart';
import 'package:espy/pages/login_page.dart';
import 'package:espy/pages/top_level_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class EspyMaterialApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'espy',
      theme: context.watch<AppConfigModel>().theme,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          print('authStateChanges = ${snapshot.connectionState}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            // TODO: Show a loading screen.
            return Scaffold();
          }

          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return TopLevelPage();
            } else {
              return LoginPage();
            }
          }
          return Scaffold();
        },
      ),
      // routes: {
      //   '/games': (context) {
      //     return GameListPage();
      //   },
      //   '/profile': (context) {
      //     return ProfilePage();
      //   },
      // },
      navigatorObservers: [routeObserver],
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/games':
            return MaterialPageRoute(
                builder: (_) =>
                    GameListPage(filter: settings.arguments as String));
          case '/details':
            return MaterialPageRoute(
                builder: (_) =>
                    GameDetailsPage(id: settings.arguments as String));
          case '/profile':
            return MaterialPageRoute(builder: (_) => ProfilePage());
          default:
            return MaterialPageRoute(builder: (_) {
              return Scaffold(
                body: Center(
                  child: Text('Page not found :('),
                ),
              );
            });
        }
      },
    );
  }
}

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();
