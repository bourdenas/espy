import 'dart:math';

import 'package:espy/modules/models/config_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/widgets/dialogs/auth_dialog.dart';
import 'package:espy/widgets/dialogs/search_dialog.dart';
import 'package:espy/widgets/library/game_library.dart'
    show GameLibrary, LibraryLayout;
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

class _EspyScaffoldState extends State<EspyScaffold> {
  List<_LibraryView> _libraryViews = const [
    _LibraryView(LibraryLayout.GRID, Icons.photo),
    _LibraryView(LibraryLayout.LIST, Icons.list),
  ];
  int _libraryViewIndex = 0;

  List<_CardsView> _cardViews = const [
    _CardsView(CardDecoration.TAGS, Icons.label),
    _CardsView(CardDecoration.INFO, Icons.info),
    _CardsView(CardDecoration.EMPTY, Icons.label_off),
  ];
  int _cardViewIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final auth = context.watch<UserModel>();
      final appConfig = context.read<AppConfig>();
      appConfig.windowWidth = constraints.maxWidth;

      return Row(children: [
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
                        Icon(_libraryViews[_libraryViewIndex].iconData),
                        Icon(_cardViews[_cardViewIndex].iconData),
                      ],
                      isSelected: [false, false],
                      onPressed: (index) {
                        setState(() {
                          if (index == 0) {
                            _libraryViewIndex =
                                (_libraryViewIndex + 1) % _libraryViews.length;
                          } else if (index == 1) {
                            _cardViewIndex =
                                (_cardViewIndex + 1) % _cardViews.length;
                            appConfig.cardDecoration =
                                _cardViews[_cardViewIndex].decoration;
                          }
                        });
                      },
                    ),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16)),
                  if (!auth.signedIn)
                    TextButton(
                      child: Text("Sign In"),
                      onPressed: () => AuthDialog.show(context),
                    )
                  else if (appConfig.isNotMobile) ...[
                    TextButton(
                      child: Text("Sign Out"),
                      onPressed: () => auth.signOut(),
                    ),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16)),
                  ],
                ],
              ),
            ),
            drawer: appConfig.isMobile ? EspyDrawer() : null,
            body: auth.signedIn
                ? GameLibrary(view: _libraryViews[_libraryViewIndex].layout)
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
      ]);
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
