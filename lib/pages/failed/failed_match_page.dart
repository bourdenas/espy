import 'package:espy/pages/failed/failed_match_list_view.dart';
import 'package:flutter/material.dart';

class FailedMatchPage extends StatefulWidget {
  const FailedMatchPage({Key? key}) : super(key: key);

  @override
  FailedMatchPageState createState() => FailedMatchPageState();
}

class FailedMatchPageState extends State<FailedMatchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Unmatched Games'),
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0.0,
      ),
      body: const FailedMatchListView(),
    );
  }
}
