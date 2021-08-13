import 'package:espy/modules/models/config_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/widgets/dialogs/auth_dialog.dart';
import 'package:espy/widgets/dialogs/search_dialog.dart';
import 'package:espy/widgets/library/game_library.dart'
    show GameLibrary, LibraryView;
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
  List<bool> _viewSelection = [true, false, false];
  List<LibraryView> _libraryViews = const [
    LibraryView.GRID,
    LibraryView.LIST,
    LibraryView.TABLE
  ];
  LibraryView _view = LibraryView.GRID;

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
                        Icon(Icons.grid_4x4),
                        Icon(Icons.list),
                        Icon(Icons.table_view),
                      ],
                      isSelected: _viewSelection,
                      onPressed: (index) {
                        setState(() {
                          _viewSelection = List<bool>.generate(
                              _libraryViews.length, (i) => i == index);
                          _view = _libraryViews[index];
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
            body: auth.signedIn ? GameLibrary(view: _view) : EmptyLibrary(),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Material(
          child: Center(
            child: Text(
                'Connect your storefront accounts in settings to retrieve your game library.'),
          ),
        ),
      ],
    );
  }
}
