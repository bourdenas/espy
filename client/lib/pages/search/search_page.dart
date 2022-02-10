import 'package:espy/pages/search/search_results.dart';
import 'package:espy/pages/search/search_text_field.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchTextField(
              onChanged: (text) {
                text.toLowerCase().split(' ');
                setState(() {
                  _text = text;
                });
              },
            ),
            SearchResults(query: _text),
          ],
        ),
      ),
    );
  }

  String _text = '';
}
