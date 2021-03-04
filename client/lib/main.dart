import 'package:espy/widgets/espy_navigation_rail.dart' show EspyNavigationRail;
import 'package:flutter/material.dart';

void main() {
  runApp(EspyApp());
}

class EspyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'espy',
      theme: ThemeData.dark(),
      home: HomePage(title: 'espy'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _selectItemIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Row(children: [
        EspyNavigationRail(true),
        VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You have selected:'),
              Text(
                '$_selectedIndex',
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
