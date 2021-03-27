import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/widgets/espy_drawer.dart' show EspyDrawer;
import 'package:espy/widgets/espy_navigation_rail.dart' show EspyNavigationRail;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EspyScaffold extends StatefulWidget {
  final Widget body;

  EspyScaffold({required this.body});

  @override
  State<StatefulWidget> createState() => _EspyScaffoldState(body: body);
}

class _EspyScaffoldState extends State<EspyScaffold> {
  final Widget body;

  _EspyScaffoldState({required this.body});

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Row(children: [
        // if (constraints.maxWidth > 800)
        //   EspyNavigationRail(constraints.maxWidth > 3200),
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
              ),
              drawer: constraints.maxWidth <= 800 ? EspyDrawer() : null,
              body: body),
        ),
      ]);
    });
  }
}
