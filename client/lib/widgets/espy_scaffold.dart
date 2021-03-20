import 'package:espy/widgets/espy_drawer.dart' show EspyDrawer;
import 'package:espy/widgets/espy_navigation_rail.dart' show EspyNavigationRail;
import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Row(children: [
        if (constraints.maxWidth > 800)
          EspyNavigationRail(constraints.maxWidth > 3200),
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
                    // controller: _filter,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search), hintText: 'Search...'),
                  ),
                ),
              ]),
            ),
            drawer: constraints.maxWidth <= 800 ? EspyDrawer() : null,
            body: body,
          ),
        ),
      ]);
    });
  }
}

class _Search extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: Icon(Icons.close), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context));
  }

  String selectedResult = '';

  @override
  Widget buildResults(BuildContext context) {
    return Container(child: Center(child: Text(selectedResult)));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> suggestions = ['Adventure', 'Strategy', 'RPG'];

    return ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(suggestions[index]));
        });
  }
}
