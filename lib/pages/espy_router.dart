import 'dart:io';

import 'package:espy/modules/intents/add_game_intent.dart';
import 'package:espy/modules/intents/edit_dialog_intent.dart';
import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/pages/calendar/calendar_page.dart';
import 'package:espy/pages/collection/collection_page.dart';
import 'package:espy/pages/company/company_page.dart';
import 'package:espy/pages/explore/explore_page.dart';
import 'package:espy/pages/details/game_details_page.dart';
import 'package:espy/pages/edit/edit_entry_page.dart';
import 'package:espy/pages/library/library_page.dart';
import 'package:espy/pages/view/view_page.dart';
import 'package:espy/widgets/scaffold/espy_scaffold.dart';
import 'package:espy/pages/home/home_content.dart';
import 'package:espy/pages/profile/login_page.dart';
import 'package:espy/pages/profile/profile_page.dart';
import 'package:espy/pages/search/search_page.dart';
import 'package:espy/pages/unresolved/unresolved_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EspyRouter extends StatelessWidget {
  final _router = GoRouter(
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          name: 'home',
          child: EspyScaffold(
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
          name: 'games',
          child: EspyScaffold(
            body: LibraryPage(
              state.uri.queryParameters['view'] == 'library'
                  ? context.watch<LibraryViewModel>().library
                  : context
                      .watch<LibraryViewModel>()
                      .getEntries(state.uri.queryParameters['view'] ?? ''),
              title: state.uri.queryParameters['title'] ?? '',
            ),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'view',
        path: '/view',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          name: 'view',
          child: EspyScaffold(
            body: ViewPage(
              title: state.uri.queryParameters['title'] ?? '',
              viewId: state.uri.queryParameters['view'] ?? '',
            ),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'explore',
        path: '/explore',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          name: 'explore',
          child: EspyScaffold(
            body: const ExplorePage(),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'calendar',
        path: '/calendar',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          name: 'calendar',
          child: EspyScaffold(
            body: CalendarPage(),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'details',
        path: '/details/:gid',
        pageBuilder: (context, state) => NoTransitionPage(
          name: 'details',
          arguments: state.pathParameters['gid']!,
          child: EspyScaffold(
            body: GameDetailsPage(id: state.pathParameters['gid']!),
            path: state.path!,
          ),
        ),
        routes: [
          GoRoute(
            name: 'edit',
            path: 'edit',
            builder: (context, state) =>
                EditEntryPage(id: state.pathParameters['gid']!),
          ),
        ],
      ),
      GoRoute(
        name: 'unresolved',
        path: '/unresolved',
        pageBuilder: (context, state) => NoTransitionPage(
          name: 'unresolved',
          child: EspyScaffold(
            body: const UnresolvedPage(),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'search',
        path: '/search',
        pageBuilder: (context, state) => NoTransitionPage(
          name: 'search',
          child: EspyScaffold(
            body: const SearchPage(),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'company',
        path: '/company/:name',
        pageBuilder: (context, state) => NoTransitionPage(
          name: 'company',
          arguments: state.pathParameters['name']!,
          child: EspyScaffold(
            body: CompanyPage(name: state.pathParameters['name']!),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'collection',
        path: '/collection/:name',
        pageBuilder: (context, state) => NoTransitionPage(
          name: 'collection',
          arguments: state.pathParameters['name']!,
          child: EspyScaffold(
            body: CollectionPage(name: state.pathParameters['name']!),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'profile',
        path: '/profile',
        pageBuilder: (context, state) => NoTransitionPage(
          name: 'profile',
          child: EspyScaffold(
            body: const ProfilePage(),
            path: state.path!,
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => const EspyScaffold(
      body: Center(
        child: Text('Page not found :('),
      ),
      path: '',
    ),
  );

  EspyRouter({super.key});

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
                theme: context.watch<AppConfigModel>().theme,
                routeInformationProvider: _router.routeInformationProvider,
                routeInformationParser: _router.routeInformationParser,
                routerDelegate: _router.routerDelegate,
                title: 'espy',
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
