import 'package:espy/modules/intents/add_game_intent.dart';
import 'package:espy/modules/intents/edit_dialog_intent.dart';
import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
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
import 'package:espy/pages/failed/failed_match_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EspyRouter extends StatelessWidget {
  final _router = GoRouter(
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: TopLevelPage(
            body: const HomeContent(),
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
            body: GameDetailsPage(id: state.params['gid']!),
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
        ],
      ),
      GoRoute(
        name: 'search',
        path: '/search',
        pageBuilder: (context, state) => NoTransitionPage(
          child: TopLevelPage(
            body: const SearchPage(),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'unmatched',
        path: '/unmatched',
        pageBuilder: (context, state) => NoTransitionPage(
          child: TopLevelPage(
            body: const FailedMatchPage(),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'profile',
        path: '/profile',
        pageBuilder: (context, state) => NoTransitionPage(
          child: TopLevelPage(
            body: const ProfilePage(),
            path: state.path!,
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => const TopLevelPage(
      body: Center(
        child: Text('Page not found :('),
      ),
      path: '',
    ),
  );

  EspyRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.slash): SearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true): SearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyG, control: true): HomeIntent(),
        SingleActivator(LogicalKeyboardKey.period, control: true):
            EditDialogIntent(),
        SingleActivator(LogicalKeyboardKey.keyQ, control: true):
            AddGameIntent(),
      },
      child: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // TODO: Show a loading screen.
            return const MaterialApp(home: Scaffold());
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
              return const MaterialApp(home: LoginPage());
            }
          }
          return const MaterialApp(home: Scaffold());
        },
      ),
    );
  }
}

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();
