import 'package:espy/pages/unresolved/unknown_list_view.dart';
import 'package:espy/pages/unresolved/unresolved_list_view.dart';
import 'package:flutter/material.dart';

class UnresolvedPage extends StatefulWidget {
  const UnresolvedPage({super.key});

  @override
  UnresolvedPageState createState() => UnresolvedPageState();
}

class UnresolvedPageState extends State<UnresolvedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unresolved Games'),
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0.0,
      ),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Pending Review'),
          ),
          Expanded(
            flex: 5,
            child: UnresolvedListView(),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Unknown Entries'),
          ),
          Expanded(
            flex: 2,
            child: UnknownListView(),
          ),
        ],
      ),
    );
  }
}
