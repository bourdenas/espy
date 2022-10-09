import 'dart:math';

import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/intents/title_search_intent.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/dialogs/auth_dialog.dart';
import 'package:espy/widgets/dialogs/search_dialog.dart';
import 'package:espy/widgets/library/game_library.dart' show GameLibrary;
import 'package:espy/widgets/scaffold/espy_drawer.dart' show EspyDrawer;
import 'package:espy/widgets/scaffold/espy_navigation_rail.dart'
    show EspyNavigationRail;
import 'package:espy/widgets/scaffold/searchbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EspyScaffold extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _EspyScaffoldState();
}

class _EspyScaffoldState extends State<EspyScaffold> {
  List<_LibraryView> _libraryViews = const [
    _LibraryView(LibraryLayout.GRID, Icons.photo),
    _LibraryView(LibraryLayout.EXPANDED_LIST, Icons.view_list),
    _LibraryView(LibraryLayout.LIST, Icons.list),
  ];

  List<_CardsView> _cardViews = const [
    _CardsView(CardDecoration.EMPTY, Icons.label_off),
    _CardsView(CardDecoration.INFO, Icons.info),
    _CardsView(CardDecoration.TAGS, Icons.label),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final auth = context.watch<UserModel>();
      final appConfig = context.read<AppConfigModel>();
      appConfig.windowWidth = constraints.maxWidth;

      return Actions(
        actions: {
          TitleSearchIntent: CallbackAction<TitleSearchIntent>(
              onInvoke: (intent) => setState(() {})),
          SearchIntent: CallbackAction<SearchIntent>(
              onInvoke: (intent) => SearchDialog.show(context)),
          HomeIntent: CallbackAction<HomeIntent>(
              onInvoke: (intent) =>
                  context.read<EspyRouterDelegate>().showLibrary()),
        },
        child: Focus(
          autofocus: true,
          child: Row(
            children: [
              if (appConfig.isNotMobile && auth.signedIn)
                EspyNavigationRail(appConfig.windowWidth > 3200),
              Expanded(
                child: Scaffold(
                  appBar: AppBar(
                    title: Row(
                      children: [
                        Text('espy'),
                        Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: appConfig.isNotMobile ? 32 : 16)),
                        Expanded(
                          child: appConfig.isNotMobile && auth.signedIn
                              ? Searchbar()
                              : Container(),
                        ),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16)),
                        if (auth.signedIn)
                          ToggleButtons(
                            children: [
                              Icon(_libraryViews[appConfig.libraryLayout.index]
                                  .iconData),
                              Icon(_cardViews[appConfig.cardDecoration.index]
                                  .iconData),
                            ],
                            isSelected: [false, false],
                            onPressed: (index) {
                              setState(() {
                                if (index == 0) {
                                  appConfig.nextLibraryLayout();
                                } else if (index == 1) {
                                  appConfig.nextCardDecoration();
                                }
                              });
                            },
                          ),
                        if (!auth.signedIn)
                          TextButton(
                            child: Text('Sign In'),
                            onPressed: () => AuthDialog.show(context),
                          )
                        else if (appConfig.isNotMobile) ...[
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16)),
                          TextButton(
                            child: Text('Sign Out'),
                            onPressed: () => auth.signOut(),
                          ),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16)),
                        ],
                      ],
                    ),
                  ),
                  drawer: appConfig.isMobile ? EspyDrawer() : null,
                  body: auth.signedIn
                      ? GameLibrary(
                          key: UniqueKey(),
                          view: _libraryViews[appConfig.libraryLayout.index]
                              .layout)
                      : EmptyLibrary(),
                  floatingActionButton: auth.signedIn
                      ? FloatingActionButton(
                          tooltip: 'Search',
                          child: Icon(Icons.search),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blueAccent,
                          onPressed: () => SearchDialog.show(context),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class EmptyLibrary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Material(
          child: Center(
            child: SizedBox(
              width: min(screenSize.width * .9, 800),
              child: Image.asset(
                'assets/images/espy-logo_800.png',
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LibraryView {
  final LibraryLayout layout;
  final IconData iconData;

  const _LibraryView(this.layout, this.iconData);
}

class _CardsView {
  final CardDecoration decoration;
  final IconData iconData;

  const _CardsView(this.decoration, this.iconData);
}
