import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/widgets/espy_drawer.dart' show EspyDrawer;
import 'package:espy/widgets/espy_navigation_rail.dart' show EspyNavigationRail;
import 'package:espy/widgets/game_library.dart' show GameLibrary, LibraryView;
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
      context.read<GameLibraryModel>().titleFilter =
          _searchController.text.toLowerCase();
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
  LibraryView _view = LibraryView.LIST;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Row(children: [
        if (constraints.maxWidth > 800)
          EspyNavigationRail(constraints.maxWidth > 1200),
        Expanded(
          child: Scaffold(
              appBar: AppBar(
                title: Row(children: [
                  Text('espy'),
                  Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth > 800 ? 32 : 16)),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      autofocus: kIsWeb,
                      decoration: InputDecoration(
                        prefixIcon: IconButton(
                          icon: _searchIcon,
                          onPressed: () => _searchController.clear(),
                        ),
                        hintText: 'Search...',
                      ),
                    ),
                  ),
                ]),
                actions: [
                  PopupMenuButton(
                    itemBuilder: (context) {
                      return <PopupMenuEntry<LibraryView>>[
                        CheckedPopupMenuItem(
                          value: LibraryView.GRID,
                          checked: _view == LibraryView.GRID,
                          child: Text('Grid View'),
                        ),
                        CheckedPopupMenuItem(
                          value: LibraryView.LIST,
                          checked: _view == LibraryView.LIST,
                          child: Text('List View'),
                        ),
                        CheckedPopupMenuItem(
                          value: LibraryView.TABLE,
                          checked: _view == LibraryView.TABLE,
                          child: Text('Table View'),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                            child: Slider(
                                value: 80,
                                min: 60,
                                max: 120,
                                divisions: 20,
                                label: 'Cover Size',
                                onChanged: (value) {})),
                      ];
                    },
                    onSelected: (LibraryView value) {
                      setState(() => _view = value);
                    },
                  )
                ],
              ),
              drawer: constraints.maxWidth <= 800 ? EspyDrawer() : null,
              body: GameLibrary(view: _view)),
        ),
      ]);
    });
  }
}
