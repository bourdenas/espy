import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/intents/title_search_intent.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter.dart';
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
import 'package:go_router/go_router.dart';
import 'package:provider/src/provider.dart';

class EspyMaterialApp extends StatelessWidget {
  final _router = GoRouter(
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) => TopLevelPage(),
      ),
      GoRoute(
        name: 'games',
        path: '/games',
        builder: (context, state) =>
            GameListPage(filter: LibraryFilter.fromParams(state.queryParams)),
      ),
      GoRoute(
        name: 'details',
        path: '/details/:gid',
        builder: (context, state) =>
            GameDetailsPage(path: state.params['gid']!),
        routes: [
          GoRoute(
            name: 'edit',
            path: 'edit',
            builder: (context, state) =>
                EditEntryPage(id: state.params['gid']!),
          ),
          GoRoute(
            name: 'web',
            path: 'web',
            builder: (context, state) =>
                WebPage(url: state.queryParams['url']!),
          ),
        ],
      ),
      GoRoute(
        name: 'search',
        path: '/search',
        builder: (context, state) => SearchPage(),
      ),
      GoRoute(
        name: 'unmatched',
        path: '/unmatched',
        builder: (context, state) => UnmatchedPage(),
      ),
      GoRoute(
        name: 'profile',
        path: '/profile',
        builder: (context, state) => ProfilePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found :('),
      ),
    ),
  );

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
      child: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          print('authStateChanges = ${snapshot.connectionState}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            // TODO: Show a loading screen.
            return MaterialApp(home: Scaffold());
          }

          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return MaterialApp.router(
                routeInformationProvider: _router.routeInformationProvider,
                routeInformationParser: _router.routeInformationParser,
                routerDelegate: _router.routerDelegate,
                title: 'espy',
                theme: context.watch<AppConfigModel>().theme,
                debugShowCheckedModeBanner: false,
              );
            } else {
              return MaterialApp(home: LoginPage());
            }
          }
          return MaterialApp(home: Scaffold());
        },
      ),
    );
  }
}

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();
