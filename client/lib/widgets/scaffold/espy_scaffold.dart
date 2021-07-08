import 'package:espy/modules/models/appbar_search_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/widgets/dialogs/auth_dialog.dart';
import 'package:espy/widgets/scaffold/espy_drawer.dart' show EspyDrawer;
import 'package:espy/widgets/scaffold/espy_navigation_rail.dart'
    show EspyNavigationRail;
import 'package:espy/widgets/library/game_library.dart'
    show GameLibrary, LibraryView;
import 'package:espy/widgets/dialogs/search_dialog.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EspyScaffold extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _EspyScaffoldState();
}

class _EspyScaffoldState extends State<EspyScaffold> {
  @override
  void initState() {
    super.initState();

    context.read<AppBarSearchModel>().controller = _searchController;

    _searchController.addListener(() {
      final text = _searchController.text.toLowerCase();
      if (text.isNotEmpty && _searchIcon.icon != Icons.close) {
        setState(() {
          _searchIcon = Icon(Icons.close);
        });
      }
      if (text.isEmpty && _searchIcon.icon != Icons.search) {
        setState(() {
          _searchIcon = Icon(Icons.search);
        });
      }
      context.read<AppBarSearchModel>().text = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Icon _searchIcon = Icon(Icons.search);

  List<bool> _viewSelection = [true, false, false];
  final List<LibraryView> _libraryViews = const [
    LibraryView.GRID,
    LibraryView.LIST,
    LibraryView.TABLE
  ];
  LibraryView _view = LibraryView.GRID;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final auth = context.watch<UserModel>();
      return Row(children: [
        if (constraints.maxWidth > 800)
          EspyNavigationRail(constraints.maxWidth > 3200),
        Expanded(
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Text('espy'),
                  Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth > 800 ? 32 : 16)),
                  Expanded(
                    child: auth.signedIn
                        ? TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: kIsWeb,
                            decoration: InputDecoration(
                              prefixIcon: IconButton(
                                icon: _searchIcon,
                                onPressed: () => _searchController.clear(),
                              ),
                              hintText: 'Title search...',
                            ),
                          )
                        : Container(),
                  ),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16)),
                  if (auth.signedIn)
                    ToggleButtons(
                      children: const [
                        Icon(Icons.grid_4x4),
                        Icon(Icons.list),
                        Icon(Icons.table_view),
                      ],
                      isSelected: _viewSelection,
                      onPressed: (index) {
                        setState(() {
                          _viewSelection =
                              List<bool>.generate(3, (i) => i == index);
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
                  else
                    TextButton(
                      child: Text("Sign Out"),
                      onPressed: () => auth.signOut(),
                    ),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16)),
                ],
              ),
            ),
            drawer: constraints.maxWidth <= 800 ? EspyDrawer() : null,
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
