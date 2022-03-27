import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/intents/title_search_intent.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/details/game_details_page.dart';
import 'package:espy/pages/edit/edit_entry_page.dart';
import 'package:espy/pages/gamelist/game_list_page.dart';
import 'package:espy/pages/login_page.dart';
import 'package:espy/pages/search/search_page.dart';
import 'package:espy/pages/top_level_page.dart';
import 'package:espy/pages/unmatched/unmatched_page.dart';
import 'package:espy/widgets/webpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/src/provider.dart';

class EspyMaterialApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        SingleActivator(LogicalKeyboardKey.slash): const TitleSearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true):
            const SearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyG, control: true):
            const HomeIntent(),
      },
      child: MaterialApp(
        title: 'espy',
        theme: context.watch<AppConfigModel>().theme,
        debugShowCheckedModeBanner: false,
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
        navigatorObservers: [routeObserver],
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case '/home':
              return MaterialPageRoute(
                builder: (_) => TopLevelPage(),
                settings: settings,
              );
            case '/games':
              return MaterialPageRoute(
                builder: (_) =>
                    GameListPage(filter: settings.arguments as String),
                settings: settings,
              );
            case '/details':
              return MaterialPageRoute(
                builder: (_) =>
                    GameDetailsPage(id: settings.arguments as String),
                settings: settings,
              );
            case '/edit':
              return MaterialPageRoute(
                builder: (_) => EditEntryPage(id: settings.arguments as String),
                settings: settings,
              );
            case '/web':
              return MaterialPageRoute(
                builder: (_) => WebPage(url: settings.arguments as String),
                settings: settings,
              );
            case '/search':
              return MaterialPageRoute(
                builder: (_) => SearchPage(),
                settings: settings,
              );
            case '/unmatched':
              return MaterialPageRoute(
                builder: (_) => UnmatchedPage(),
                settings: settings,
              );
            case '/profile':
              return MaterialPageRoute(
                builder: (_) => ProfilePage(),
                settings: settings,
              );
            default:
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: Center(
                    child: Text('Page not found :('),
                  ),
                ),
                settings: settings,
              );
          }
        },
      ),
    );
  }
}

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();
