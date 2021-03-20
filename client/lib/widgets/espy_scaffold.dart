import 'package:espy/widgets/espy_drawer.dart' show EspyDrawer;
import 'package:espy/widgets/espy_navigation_rail.dart' show EspyNavigationRail;
import 'package:flutter/material.dart';

class EspyScaffold extends StatelessWidget {
  final Widget body;

  EspyScaffold({required this.body});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          title: Text('espy'),
          actions: [
            IconButton(
                icon: const Icon(Icons.search),
                onPressed: () =>
                    showSearch(context: context, delegate: _Search()))
          ],
        ),
        drawer: constraints.maxWidth <= 800 ? EspyDrawer() : null,
        body: Row(
          children: [
            if (constraints.maxWidth > 800) ...[
              EspyNavigationRail(constraints.maxWidth > 1200),
              VerticalDivider(thickness: 1, width: 1)
            ],
            Expanded(child: body),
          ],
        ),
      );
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
