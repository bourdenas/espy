import 'package:espy/modules/intents/add_game_intent.dart';
import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/intents/title_search_intent.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/pages/details/game_details_page.dart';
import 'package:espy/pages/edit/edit_entry_page.dart';
import 'package:espy/pages/gamelist/game_list_page.dart';
import 'package:espy/pages/home/home_content.dart';
import 'package:espy/pages/profile/login_page.dart';
import 'package:espy/pages/profile/profile_page.dart';
import 'package:espy/pages/search/search_page.dart';
import 'package:espy/pages/top_level_page.dart';
import 'package:espy/pages/unmatched/unmatched_page.dart';
import 'package:espy/widgets/webpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/src/provider.dart';

class EspyRouter extends StatelessWidget {
  final _router = GoRouter(
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: TopLevelPage(
            body: HomeContent(),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'games',
        path: '/games',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: TopLevelPage(
            body: GameListPage(
                filter: LibraryFilter.fromParams(state.queryParams)),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'details',
        path: '/details/:gid',
        pageBuilder: (context, state) => NoTransitionPage(
          child: TopLevelPage(
            body: GameDetailsPage(path: state.params['gid']!),
            path: state.path!,
          ),
        ),
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
        pageBuilder: (context, state) => NoTransitionPage(
          child: TopLevelPage(
            body: SearchPage(),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'unmatched',
        path: '/unmatched',
        pageBuilder: (context, state) => NoTransitionPage(
          child: TopLevelPage(
            body: UnmatchedPage(),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'profile',
        path: '/profile',
        pageBuilder: (context, state) => NoTransitionPage(
          child: TopLevelPage(
            body: ProfilePage(),
            path: state.path!,
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => TopLevelPage(
      body: Center(
        child: Text('Page not found :('),
      ),
      path: '',
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
        SingleActivator(LogicalKeyboardKey.keyQ, control: true):
            const AddGameIntent(),
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
