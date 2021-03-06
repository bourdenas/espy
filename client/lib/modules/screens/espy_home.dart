import 'package:espy/proto/igdbapi.pb.dart';
import 'package:espy/proto/library.pb.dart';
import 'package:espy/widgets/espy_drawer.dart' show EspyDrawer;
import 'package:espy/widgets/espy_game_grid.dart';
import 'package:espy/widgets/espy_navigation_rail.dart' show EspyNavigationRail;
import 'package:flutter/material.dart';

class EspyHome extends StatefulWidget {
  EspyHome({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<EspyHome> {
  int _selectedIndex = 0;

  void _selectItemIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        drawer: constraints.maxWidth <= 800 ? EspyDrawer() : null,
        body: Row(children: [
          if (constraints.maxWidth > 800) ...[
            EspyNavigationRail(constraints.maxWidth > 1200),
            VerticalDivider(thickness: 1, width: 1)
          ],
          Expanded(
            child: EspyGameGrid([
              GameEntry()..game = (Game()..name = 'XCOM 2'),
              GameEntry()..game = (Game()..name = 'Baldur\'s Gate 3'),
              GameEntry()..game = (Game()..name = 'Europa Universalis 4'),
            ]),
          ),
        ]),
      );
    });
  }
}
