import 'package:espy/pages/unresolved/unknown_list_view.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Unresolved Games'),
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0.0,
      ),
      body: const UnknownListView(),
    );
  }
}
