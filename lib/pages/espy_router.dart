import 'dart:io';

import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/intents/add_game_intent.dart';
import 'package:espy/modules/intents/edit_dialog_intent.dart';
import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/frontpage_model.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:espy/pages/browse/browse_page.dart';
import 'package:espy/pages/details/game_details_page.dart';
import 'package:espy/pages/edit/edit_entry_page.dart';
import 'package:espy/pages/library/library_page.dart';
import 'package:espy/pages/timeline/timeline_page.dart';
import 'package:espy/pages/timeline/timeline_view.dart';
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
          child: context.read<UserModel>().isSignedIn
              ? EspyScaffold(
                  body: const HomeContent(),
                  path: state.path!,
                )
              : EspyScaffold(
                  body: const TimelineView(
                    scrollToLabel: 'Mar',
                    year: '2024',
                  ),
                  path: state.path!,
                ),
        ),
      ),
      GoRoute(
        // Annual releases.
        name: 'years',
        path: '/years',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          name: 'years',
          child: EspyScaffold(
            body: const TimelinePage(year: '2024'),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'browse',
        path: '/browse',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          name: 'browse',
          child: EspyScaffold(
            body: const BrowsePage(),
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
            body: const LibraryPage(),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        name: 'wishlist',
        path: '/wishlist',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          name: 'wishlist',
          child: EspyScaffold(
            body: LibraryPage(
              entries: context.watch<WishlistModel>().entries,
            ),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        // Vertical timeline view that shows releases by month.
        name: 'releases',
        path: '/releases/:label/:year',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          name: 'releases',
          child: EspyScaffold(
            body: TimelineView(
              scrollToLabel: state.pathParameters['label'],
              year: state.pathParameters['year'],
            ),
            path: state.path!,
          ),
        ),
      ),
      GoRoute(
        // Library view month of game releases from a timeline view.
        name: 'view',
        path: '/view/:label/:year',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          name: 'view',
          child: EspyScaffold(
            body: LibraryPage(
              entries: context
                  .read<TimelineModel>()
                  .releases
                  .firstWhere(
                    (e) =>
                        e.label == state.pathParameters['label'] &&
                        e.year == state.pathParameters['year'],
                    orElse: () => context
                        .read<FrontpageModel>()
                        .releases
                        .firstWhere((e) =>
                            e.label == state.pathParameters['label'] &&
                            e.year == state.pathParameters['year']),
                  )
                  .games
                  .map((digest) => LibraryEntry.fromGameDigest(digest)),
            ),
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
            if (snapshot.hasData || (!kIsWeb && Platform.isAndroid)) {
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
