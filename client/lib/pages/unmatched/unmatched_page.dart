import 'package:espy/pages/unmatched/unmatched_list_view.dart';
import 'package:flutter/material.dart';

class UnmatchedPage extends StatefulWidget {
  const UnmatchedPage();

  @override
  _UnmatchedPageState createState() => _UnmatchedPageState();
}

class _UnmatchedPageState extends State<UnmatchedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Unmatched Games'),
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0.0,
      ),
      body: UnmatchedListView(),
    );
  }
}
